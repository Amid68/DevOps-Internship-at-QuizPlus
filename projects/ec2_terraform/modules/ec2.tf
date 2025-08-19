locals {
  ubuntu_ami_id = "ami-042b4708b1d05f512"
}

resource "aws_instance" "proc_mon" {
  ami                     = local.ubuntu_ami_id
  instance_type           = var.instance_type
  key_name                = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.https.id,
    aws_security_group.egress.id
  ]

  subnet_id               = data.aws_subnets.default.ids[0]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
