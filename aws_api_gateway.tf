resource "aws_api_gateway_rest_api" "analytics" {
  name = "Analytics"

  description = "Analytics API to accept incoming Listening Events"
  endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-analytics-api-gateway"
    "project"     = var.project
  }
}

resource "aws_api_gateway_resource" "analytics_events" {
  rest_api_id = aws_api_gateway_rest_api.analytics.id
  parent_id   = aws_api_gateway_rest_api.analytics.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_method" "analytics_events_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.analytics_events.id
  rest_api_id   = aws_api_gateway_rest_api.analytics.id
}

resource "aws_api_gateway_integration" "analytics_events_post_lambda" {
  http_method             = "POST"
  resource_id             = aws_api_gateway_resource.analytics_events.id
  rest_api_id             = aws_api_gateway_rest_api.analytics.id
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.live_listening_event_producer.invoke_arn
}

resource "aws_api_gateway_method_response" "analytics_events_post" {
  http_method = aws_api_gateway_method.analytics_events_post.http_method
  resource_id = aws_api_gateway_resource.analytics_events.id
  rest_api_id = aws_api_gateway_rest_api.analytics.id
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "analytics_events_post" {
  http_method = aws_api_gateway_method.analytics_events_post.http_method
  resource_id = aws_api_gateway_resource.analytics_events.id
  rest_api_id = aws_api_gateway_rest_api.analytics.id
  status_code = aws_api_gateway_method_response.analytics_events_post.status_code

  depends_on = [
    aws_api_gateway_integration.analytics_events_post_lambda
  ]
}

resource "aws_lambda_permission" "lambda_permission_for_analytics_api" {
  statement_id  = "AllowAnalyticsAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.live_listening_event_producer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.analytics.execution_arn}/*/*/*"
}


resource "aws_cloudwatch_log_group" "analytics_api" {
  name = "${var.project}-cloudwatch-log-group-for-analytics-api"
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-cloudwatch-log-group-for-analytics-api"
    "project"     = var.project
  }
}

data "aws_iam_policy" "aws_api_gateway_push_to_cloudwatch_logs" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role" "api_gateway_access_to_logs" {
  name = "${var.project}-ApiGatewayAccessToLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
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

resource "aws_iam_role_policy_attachment" "aws_api_gateway_cloudwatch_logs_role" {
  policy_arn = data.aws_iam_policy.aws_api_gateway_push_to_cloudwatch_logs.arn
  role       = aws_iam_role.api_gateway_access_to_logs.name
}

resource "aws_api_gateway_account" "analytics" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_access_to_logs.arn
}

resource "aws_api_gateway_deployment" "analytics" {
  rest_api_id = aws_api_gateway_rest_api.analytics.id
  description = "Analytics API deployment"

  triggers = {
    "redeployment" = sha1(jsonencode([
      aws_api_gateway_resource.analytics_events.id,
      aws_api_gateway_method.analytics_events_post.id,
      aws_api_gateway_integration.analytics_events_post_lambda.id,
      aws_api_gateway_integration_response.analytics_events_post.id,
      aws_api_gateway_method_response.analytics_events_post.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "analytics_v1" {
  deployment_id = aws_api_gateway_deployment.analytics.id
  rest_api_id   = aws_api_gateway_rest_api.analytics.id
  stage_name    = "v1"

  depends_on = [aws_cloudwatch_log_group.analytics_api]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.analytics_api.arn
    format = jsonencode(
      {
        requestId         = "$context.requestId"
        extendedRequestId = "$context.extendedRequestId"
        ip                = "$context.identity.sourceIp"
        caller            = "$context.identity.caller"
        user              = "$context.identity.user"
        requestTime       = "$context.requestTime"
        httpMethod        = "$context.httpMethod"
        resourcePath      = "$context.resourcePath"
        status            = "$context.status"
        protocol          = "$context.protocol"
        responseLength    = "$context.responseLength"
    })
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-analytics-stage-v1"
    "project"     = var.project
  }
}

resource "aws_api_gateway_method_settings" "analytics_events_post" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.analytics.id
  stage_name  = aws_api_gateway_stage.analytics_v1.stage_name
  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}
