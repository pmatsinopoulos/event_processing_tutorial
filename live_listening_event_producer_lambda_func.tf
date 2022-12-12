data "aws_iam_policy" "aws_lambda_basic_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "live_listening_event_producer_lambda_exec_role" {
  name = "${var.project}-LiveListeningEventProducerLambdaExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}/LiveListeningEventProducerLambdaExecRole"
    "project"     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_policy_attached_to_exec_role" {
  policy_arn = data.aws_iam_policy.aws_lambda_basic_execution_role.arn
  role       = aws_iam_role.live_listening_event_producer_lambda_exec_role.name
}

resource "aws_lambda_function" "live_listening_event_producer" {
  function_name = "${var.project}-LiveListeningEventProducer"
  description   = "Accepts an 'event' and pushes its payload into the Kafka topic: live-listening-events"
  role          = aws_iam_role.live_listening_event_producer_lambda_exec_role.arn
  image_uri     = "${aws_ecr_repository.live_listening_event_producer_lambda.repository_url}:latest"
  package_type  = "Image"
  handler       = "app.handler"
  timeout       = 30
  architectures = ["x86_64"]
  environment {
    variables = {
      KAFKA_BROKERS = aws_msk_cluster.msk_cluster.bootstrap_brokers
    }
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}/LiveListeningEventProducer"
    "project"     = var.project
  }
}
