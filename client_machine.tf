data "aws_ami" "client" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.delete-on-termination"
    values = ["true"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["137112412989"] # AWS
}

data "aws_key_pair" "client" {
  key_name = var.aws_ec2_client.key_pair
}

resource "aws_security_group" "client" {
  name        = "${var.project}-security-group-client"
  description = "Allow SSH traffic from anywhere to anywhere"
  vpc_id      = aws_vpc.msk_demo.id
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outgoing from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-security-group-client"
    "project"     = var.project
  }
}

resource "aws_instance" "client" {
  ami               = data.aws_ami.client.id
  instance_type     = var.aws_ec2_client.instance_type
  availability_zone = "${var.region}a"
  subnet_id         = aws_subnet.msk_demo1.id
  vpc_security_group_ids = [
    aws_vpc.msk_demo.default_security_group_id,
    aws_security_group.client.id
  ]
  key_name                    = data.aws_key_pair.client.key_name
  associate_public_ip_address = true

  tags = {
    "environment" = var.environment
    "Name"        = "${var.project}-client-machine"
    "project"     = var.project
  }
}
