resource "aws_ecr_repository" "live_listening_event_consumer" {
  name = "${var.project}/live_listening_event_consumer"

  depends_on = [
    null_resource.aws_ecr_login
  ]

  force_delete = true

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-live-listening-event-consumer"
    "project"     = var.project
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_consumer"
    command     = "docker build -t ${self.name} ."
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_consumer"
    command     = "docker tag ${self.name}:latest ${self.repository_url}:latest"
  }

  provisioner "local-exec" {
    working_dir = "./live_listening_event_consumer"
    command     = "docker push ${self.repository_url}:latest"
  }

  # Destroy Phase
  # -------------
  provisioner "local-exec" {
    when        = destroy
    working_dir = "./live_listening_event_consumer"
    command     = "docker image rm --force ${self.name}:latest || true"
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = "./live_listening_event_consumer"
    command     = "docker image rm --force ${self.repository_url}:latest || true"
  }
}
