resource "aws_security_group" "ec2" {
  name_prefix = "${var.sg_environment}-ec2-"
  vpc_id      = var.vpc_id
  description = "Security group for ${var.sg_environment} EC2 instance"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = var.http_port
    to_port     = var.http_port
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
    Name        = "${var.sg_environment}-ec2-sg"
    Environment = var.sg_environment
    ManagedBy   = "terraform"
  }
}
