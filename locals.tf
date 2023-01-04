locals {
  kafka_tar_archive = "kafka_${var.scala_version}-${var.kafka_version}"
  # This is downloaded from "https://www.confluent.io/hub/confluentinc/kafka-connect-s3" page.
  # Download the ZIP file: https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-s3/versions/10.3.0/confluentinc-kafka-connect-s3-10.3.0.zip
  kafka_connector_filename   = "confluentinc-kafka-connect-s3-10.3.0.zip"
  kafka_connect_path_to_file = "~/Downloads/${local.kafka_connector_filename}"
}
