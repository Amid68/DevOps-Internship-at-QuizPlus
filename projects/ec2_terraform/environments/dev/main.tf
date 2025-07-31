provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "dev-ec2-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for dev EC2 instance"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["158.140.75.65/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "dev-ec2-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "ec2" {
  source = "../../modules/ec2"

  environment        = "dev"
  project_name       = "fastAPI_ProcMon"
  instance_type      = "t3.micro"
  root_volume_size   = 30
  subnet_id          = data.aws_subnets.default.ids[0]
  security_group_ids = [aws_security_group.ec2.id]
  key_name           = "fastapi-dev-key"
}
