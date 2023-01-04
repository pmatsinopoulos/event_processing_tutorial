resource "aws_s3_bucket" "msk_connect_sink" {
  bucket        = "${var.company_name}-${var.project}-msk-connect-sink"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    "environment" = var.environment
    "Name"        = "${var.company_name}-${var.project}-msk-connect-sink"
    "project"     = var.project
  }
}

resource "aws_iam_policy" "access_msk_connect_s3_sink" {
  name        = "${var.project}-access-msk-connect-s3-sink"
  description = "Allows access to the S3 bucket ${aws_s3_bucket.msk_connect_sink.arn}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ],
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = "${aws_s3_bucket.msk_connect_sink.arn}/*"
      }
    ]
  })

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-access-msk-connect-s3-sink"
    "project"     = var.project
  }
}

resource "aws_iam_role" "access_msk_connect_s3_sink" {
  name        = "${var.project}-AccessMskConnectS3SinkRole"
  description = "Permission to write to S3 bucket. Kafka Connect service will be allowed to take this role."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "kafkaconnect.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-access-msk-connect-s3-sink"
    "project"     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "access_msk_connect_s3_sink" {
  policy_arn = aws_iam_policy.access_msk_connect_s3_sink.arn
  role       = aws_iam_role.access_msk_connect_s3_sink.name
}

resource "aws_vpc_endpoint" "s3_sink_to_msk_cluster_vpc" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.msk_demo.id
  route_table_ids   = [aws_vpc.msk_demo.main_route_table_id]
  service_name      = "com.amazonaws.${var.region}.s3"

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-s3-sink-to-msk-cluster-vpc"
    "project"     = var.project
  }
}

resource "aws_s3_object" "s3_sink_msk_connect_custom_plugin_code" {
  bucket = aws_s3_bucket.msk_connect_sink.id
  key    = local.kafka_connector_filename
  source = local.kafka_connect_path_to_file
}

resource "aws_mskconnect_custom_plugin" "s3_sink" {
  name         = "${var.project}-s3-sink-plugin"
  description  = "Custom Plugin for S3 Sink"
  content_type = "ZIP"
  location {
    s3 {
      bucket_arn = aws_s3_bucket.msk_connect_sink.arn
      file_key   = aws_s3_object.s3_sink_msk_connect_custom_plugin_code.key
    }
  }
}

resource "aws_cloudwatch_log_group" "s3_sink_msk_connector" {
  name = "${var.project}-s3-sink-msk-connector"
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-cloudwatch-log-group-for-s3-sink-msk-connector"
    "project"     = var.project
  }
}

resource "aws_mskconnect_connector" "s3_sink" {
  name = "${var.project}-s3-sink"

  kafkaconnect_version = "2.7.1"

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.s3_sink.arn
      revision = aws_mskconnect_custom_plugin.s3_sink.latest_revision
    }
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.msk_cluster.bootstrap_brokers_tls
      vpc {
        security_groups = [aws_vpc.msk_demo.default_security_group_id]
        subnets         = [for k, v in var.vpc_subnets : aws_subnet.msk_demo[k].id]
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  connector_configuration = {
    "connector.class"      = "io.confluent.connect.s3.S3SinkConnector"
    "tasks.max"            = 2
    "topics"               = var.topic_name
    "s3.region"            = var.region
    "s3.bucket.name"       = aws_s3_bucket.msk_connect_sink.id
    "flush.size"           = 1
    "storage.class"        = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"         = "io.confluent.connect.s3.format.json.JsonFormat"
    "partitioner.class"    = "io.confluent.connect.storage.partitioner.DefaultPartitioner"
    "key.converter"        = "org.apache.kafka.connect.storage.StringConverter"
    "value.converter"      = "org.apache.kafka.connect.storage.StringConverter"
    "schema.compatibility" = "NONE"
  }

  service_execution_role_arn = aws_iam_role.access_msk_connect_s3_sink.arn

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.s3_sink_msk_connector.id
      }
    }
  }
}
