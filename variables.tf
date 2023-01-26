variable "company_name" {
  type        = string
  description = "This is going to be used as a prefix before the project name for resources that require a global naming uniqueness, like S3."
  nullable    = false
}

variable "project" {
  type        = string
  description = "The name of this project, like 'msk-demo' will be used as prefix name accross many resources."
  default     = "msk-demo"
}

variable "region" {
  type        = string
  description = "AWS Region in which the MSK cluster is going to be created in. Region needs to have 3 availability zones."
  nullable    = false
}

variable "profile" {
  type        = string
  description = "AWS Credentials Profile name. You need to have it set up with aws cli."
  nullable    = false
}

variable "environment" {
  type        = string
  description = "This is a tag we assign to most of the resources."
  default     = "learning"
  nullable    = false
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC that will be created to host the AWS MSK cluster."
  nullable    = false
}

variable "vpc_subnets" {
  type = map(object({
    cidr_block    = string
    region_suffix = string
  }))
  description = "A map of CIDR blocks and regions for each one of the three subnets."
  nullable    = false
}

variable "aws_managed_kafka_key" {
  type        = string
  description = "The AWS Managed Kafka Key id that will be used to encrypt values at rest."
  nullable    = false
}

variable "brokers" {
  type = object({
    instance_type       = string
    storage_volume_size = number
  })
  validation {
    condition = contains([
      "kafka.t3.small",
      "kafka.m5.large",
      "kafka.m5.xlarge",
      "kafka.m5.2xlarge",
      "kafka.m5.4xlarge",
      "kafka.m5.8xlarge",
      "kafka.m5.12xlarge",
      "kafka.m5.16xlarge",
      "kafka.m5.24xlarge"
    ], var.brokers.instance_type)
    error_message = "The brokers.instance_type should be one of the values supported by AWS for MSK. See here: https://docs.aws.amazon.com/msk/latest/developerguide/msk-create-cluster.html"
  }
  nullable = false

}

variable "number_of_nodes" {
  type        = number
  description = "Number of Broker nodes in the cluster"
  nullable    = false
}

variable "kafka_version" {
  type        = string
  description = "The Kafka version to install"
  nullable    = false
}

variable "scala_version" {
  type        = string
  description = "The Scala version the Kafka binary is built for"
  nullable    = false
}

variable "aws_ec2_client" {
  type = object({
    key_pair      = string
    instance_type = string
  })
  nullable = false
}

variable "topic_name" {
  type        = string
  description = "The name of the topic the events will be published to"
  nullable    = false
  default     = "live-listening-events"
}

variable "db_analytics" {
  type = object({
    username = string
    password = string
    port     = number
    name     = string
  })
  nullable  = false
  sensitive = true
}
