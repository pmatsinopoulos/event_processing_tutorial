resource "aws_db_subnet_group" "analytics" {
  name       = "${var.project}-db-subnet-group-analytics-main"
  subnet_ids = [for k, v in var.vpc_subnets : aws_subnet.msk_demo[k].id]

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-db-subnet-group-analytics-main"
    "project"     = var.project
  }
}

resource "aws_db_instance" "analytics" {
  identifier     = "${var.project}-analytics"
  instance_class = "db.t3.micro"

  allocated_storage     = 10
  max_allocated_storage = 0
  storage_type          = "gp2"

  engine              = "postgres"
  engine_version      = "14.5"
  username            = var.db_analytics.username
  password            = var.db_analytics.password
  port                = var.db_analytics.port
  publicly_accessible = false

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  availability_zone           = "${var.region}a"

  db_subnet_group_name   = aws_db_subnet_group.analytics.id
  vpc_security_group_ids = [aws_vpc.msk_demo.default_security_group_id]

  delete_automated_backups = true

  deletion_protection = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  monitoring_interval = 0

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-db-instance-analytics"
    "project"     = var.project
  }
  copy_tags_to_snapshot = true
}
