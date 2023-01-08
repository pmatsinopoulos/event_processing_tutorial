resource "null_resource" "aws_ecr_login" {
  provisioner "local-exec" {
    working_dir = "./live_listening_event_consumer"
    command     = "aws ecr get-login-password --region ${var.region} --profile ${var.profile} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current_user.account_id}.dkr.ecr.eu-west-1.amazonaws.com"
  }
}
