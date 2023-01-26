resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project}-ECSTaskExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}/ECSTaskExecRole"
    "project"     = var.project
  }
}

data "aws_iam_policy" "aws_ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attached_to_exec_role" {
  policy_arn = data.aws_iam_policy.aws_ecs_task_execution_role.arn
  role       = aws_iam_role.ecs_task_execution.name
}

resource "aws_cloudwatch_log_group" "live_listening_event_consumer" {
  name = "${var.project}-live-listening-event-consumer"
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-cloudwatch-log-group-for-live-listening-event-consumer"
    "project"     = var.project
  }
}

resource "aws_ecs_task_definition" "live_listening_event_consumer" {
  family                   = "live-listening-event-consumer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name              = "live_listening_event_consumer"
      image             = "${aws_ecr_repository.live_listening_event_consumer.repository_url}:latest"
      memoryReservation = 128
      environment = [
        {
          name  = "KAFKA_BROKERS"
          value = "${aws_msk_cluster.msk_cluster.bootstrap_brokers}"
        },
        {
          name  = "TOPIC_NAME"
          value = "${var.topic_name}"
        },
        {
          name  = "DB_USERNAME"
          value = "${aws_db_instance.analytics.username}"
        },
        {
          name  = "DB_HOST"
          value = "${aws_db_instance.analytics.address}"
        },
        {
          name  = "DB_PORT"
          value = "${tostring(aws_db_instance.analytics.port)}"
        },
        {
          name  = "DB_DATABASE"
          value = "${var.db_analytics.name}"
        },
        {
          name  = "DB_PASSWORD"
          value = "${var.db_analytics.password}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.live_listening_event_consumer.id}"
          awslogs-region        = "${var.region}"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-live-listening-event-consumer-task-definition"
    "project"     = var.project
  }
}

resource "aws_ecs_cluster" "live_listening_event_consumer" {
  name = "${var.project}-live-listening-event-consumer"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-ecs-cluster-live-listening-event-consumer"
    "project"     = var.project
  }
}

resource "aws_ecs_service" "live_listening_event_consumer" {
  name                = "${var.project}-live-listening-event-consumer"
  cluster             = aws_ecs_cluster.live_listening_event_consumer.id
  task_definition     = aws_ecs_task_definition.live_listening_event_consumer.arn
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = [for k, v in var.vpc_subnets : aws_subnet.msk_demo[k].id]
    security_groups  = [aws_vpc.msk_demo.default_security_group_id]
    assign_public_ip = true
  }

  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count]
  }

  wait_for_steady_state = true

  enable_ecs_managed_tags = true

  propagate_tags = "TASK_DEFINITION"

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-ecs-service-live-listening-event-consumer"
    "project"     = var.project
  }
}
