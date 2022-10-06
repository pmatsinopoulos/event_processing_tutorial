terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_vpc" "msk_demo" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-vpc"
    "project"     = var.project
  }
}

resource "aws_internet_gateway" "msk_demo" {
  vpc_id = aws_vpc.msk_demo.id
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-internet-gateway"
    "project"     = var.project
  }
}

resource "aws_route" "to_internet_gateway" {
  route_table_id         = aws_vpc.msk_demo.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.msk_demo.id
}
resource "aws_subnet" "msk_demo1" {
  availability_zone = "${var.region}a"
  cidr_block        = var.vpc_subnet_cidr_blocks.subnet1
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-subnet-1"
    "project"     = var.project
  }
  vpc_id = aws_vpc.msk_demo.id
}

resource "aws_subnet" "msk_demo2" {
  availability_zone = "${var.region}b"
  cidr_block        = var.vpc_subnet_cidr_blocks.subnet2
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-subnet-2"
    "project"     = var.project
  }
  vpc_id = aws_vpc.msk_demo.id
}

resource "aws_subnet" "msk_demo3" {
  availability_zone = "${var.region}c"
  cidr_block        = var.vpc_subnet_cidr_blocks.subnet3
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-subnet-3"
    "project"     = var.project
  }
  vpc_id = aws_vpc.msk_demo.id
}

data "aws_kms_key" "aws_managed_kafka_key" {
  key_id = var.aws_managed_kafka_key
}

resource "aws_cloudwatch_log_group" "msk_demo" {
  name = "${var.project}-cloudwatch-log-group"
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-cloudwatch-log-group"
    "project"     = var.project
  }
}

resource "aws_s3_bucket" "broker_logs_bucket" {
  bucket        = "${var.company_name}-${var.project}-borker-logs-bucket"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    "environment" = var.environment
    "Name"        = "${var.company_name}-${var.project}-borker-logs-bucket"
    "project"     = var.project
  }
}

resource "aws_s3_bucket_acl" "broker_logs_bucket_acl" {
  bucket = aws_s3_bucket.broker_logs_bucket.id
  acl    = "private"
}

# Creates a provisioned MSK cluster
resource "aws_msk_cluster" "msk_cluster" {
  broker_node_group_info {
    az_distribution = "DEFAULT"
    client_subnets = [
      aws_subnet.msk_demo1.id,
      aws_subnet.msk_demo2.id,
      aws_subnet.msk_demo3.id,
    ]
    connectivity_info {
      public_access {
        type = "DISABLED"
      }
    }
    instance_type   = var.brokers.instance_type
    security_groups = [aws_vpc.msk_demo.default_security_group_id]
    storage_info {
      ebs_storage_info {
        volume_size = var.brokers.storage_volume_size
        provisioned_throughput {
          enabled = false
        }
      }
    }
  }
  client_authentication {
    unauthenticated = true
    sasl {
      iam = true
    }
  }
  cluster_name = "${var.project}-msk-cluster"
  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
    encryption_at_rest_kms_key_arn = data.aws_kms_key.aws_managed_kafka_key.arn
  }
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_demo.id
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.broker_logs_bucket.id
        prefix  = "msk-cluster"
      }
    }
  }
  number_of_broker_nodes = var.number_of_nodes
  kafka_version          = var.kafka_version
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-msk-cluster"
    "project"     = var.project
  }
}
