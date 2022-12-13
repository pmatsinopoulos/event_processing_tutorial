data "aws_caller_identity" "current_user" {}

resource "aws_ecr_repository" "live_listening_event_producer_lambda" {
  name = "${var.project}/live_listening_event_producer_lambda"

  force_delete = true

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-live-listening-event-producer-lambda"
    "project"     = var.project
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_producer"
    command     = "docker build -t ${self.name} ."
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_producer"
    command     = "docker tag ${self.name}:latest ${self.repository_url}:latest"
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_producer"
    command     = "aws ecr get-login-password --region ${var.region} --profile ${var.profile} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current_user.account_id}.dkr.ecr.eu-west-1.amazonaws.com"
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_producer"
    command     = "docker push ${self.repository_url}:latest"
  }

  # Destroy Phase
  # -------------
  provisioner "local-exec" {
    when        = destroy
    working_dir = "./live_listening_event_producer"
    command     = "docker image rm --force ${self.name}:latest || true"
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = "./live_listening_event_producer"
    command     = "docker image rm --force ${self.repository_url}:latest || true"
  }
}
