locals {
  ubuntu_ami_id = "ami-042b4708b1d05f512"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "this" {
  ami                     = local.ubuntu_ami_id
  instance_type           = var.instance_type
  key_name                = var.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-fastAPI-ec2"
  })

  lifecycle {
    create_before_destroy = true
  }
}
