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

  # provisioner "local-exec" {
  #   working_dir = "./live_listening_event_consumer"
  #   command     = "docker build -t ${self.name} ."
  # }

  # provisioner "local-exec" {
  #   working_dir = "./live_listening_event_consumer"
  #   command     = "docker tag ${self.name}:latest ${self.repository_url}:latest"
  # }

  # provisioner "local-exec" {
  #   working_dir = "./live_listening_event_consumer"
  #   command     = "docker push ${self.repository_url}:latest"
  # }

  # Destroy Phase
  # -------------
  # provisioner "local-exec" {
  #   when        = destroy
  #   working_dir = "./live_listening_event_consumer"
  #   command     = "docker image rm --force ${self.name}:latest || true"
  # }

  # provisioner "local-exec" {
  #   when        = destroy
  #   working_dir = "./live_listening_event_consumer"
  #   command     = "docker image rm --force ${self.repository_url}:latest || true"
  # }
}

resource "docker_image" "live_listening_event_consumer" {
  name = "${var.project}/live_listening_event_consumer"
  build {
    context = "./live_listening_event_consumer"
    tag     = ["${var.project}/live_listening_event_consumer:latest", "${aws_ecr_repository.live_listening_event_consumer.repository_url}:latest"]
    auth_config {
      host_name = aws_ecr_repository.live_listening_event_consumer.repository_url
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "live_listening_event_consumer/*") : filesha1(f)]))
  }

  force_remove = true
  keep_locally = false
}

resource "docker_registry_image" "live_listening_event_consumer" {
  name          = docker_image.live_listening_event_consumer.name
  keep_remotely = false
}
