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
  region  = "eu-west-1"
  profile = "me"
}

resource "aws_vpc" "msk_demo" {
  cidr_block           = "172.32.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-vpc"
    "project"     = "msk-demo"
  }
}

resource "aws_internet_gateway" "msk_demo" {
  vpc_id = aws_vpc.msk_demo.id
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-internet-gateway"
    "project"     = "msk-demo"
  }
}

resource "aws_route" "to_internet_gateway" {
  route_table_id         = aws_vpc.msk_demo.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.msk_demo.id
}
resource "aws_subnet" "msk_demo1" {
  availability_zone = "eu-west-1a"
  cidr_block        = "172.32.0.0/28" # 16 IP addresses
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-subnet-1"
    "project"     = "msk-demo"
  }
  vpc_id = aws_vpc.msk_demo.id
}

resource "aws_subnet" "msk_demo2" {
  availability_zone = "eu-west-1b"
  cidr_block        = "172.32.0.16/28" # 16 IP addresses
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-subnet-2"
    "project"     = "msk-demo"
  }
  vpc_id = aws_vpc.msk_demo.id
}

resource "aws_subnet" "msk_demo3" {
  availability_zone = "eu-west-1c"
  cidr_block        = "172.32.0.32/28" # 16 IP addresses
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-subnet-3"
    "project"     = "msk-demo"
  }
  vpc_id = aws_vpc.msk_demo.id
}

data "aws_kms_key" "aws_managed_kafka_key" {
  key_id = "447f4c1e-5b6b-4036-bbc4-6fd746983830"
}

resource "aws_cloudwatch_log_group" "msk_demo" {
  name = "msk-demo-cloudwatch-log-group"
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-cloudwatch-log-group"
    "project"     = "msk-demo"
  }
}

resource "aws_s3_bucket" "broker_logs_bucket" {
  bucket        = "pmatsinopoulos-msk-demo-borker-logs-bucket"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    "environment" = "learning"
    "Name"        = "pmatsinopoulos-msk-demo-borker-logs-bucket"
    "project"     = "msk-demo"
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
    instance_type   = "kafka.m5.large"
    security_groups = [aws_vpc.msk_demo.default_security_group_id]
    storage_info {
      ebs_storage_info {
        volume_size = 1000
        provisioned_throughput {
          enabled = false
        }
      }
    }
  }
  client_authentication {
    unauthenticated = true # What about IAM?
    sasl {
      iam = true
    }
  }
  cluster_name = "msk-demo-msk-cluster"
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
  number_of_broker_nodes = 3
  kafka_version          = "3.2.0"
  tags = {
    "environment" = "learning"
    "Name"        = "msk-demo-msk-cluster"
    "project"     = "msk-demo"
  }
}
