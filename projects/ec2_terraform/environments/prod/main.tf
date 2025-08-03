module "security_group" {
  source              = "../../modules"

  sg_environment      = "prod"
  vpc_id              = data.aws_vpc.default.id
  ssh_cidr_blocks     = ["158.140.75.65/32"]
  http_port           = 8000
}

module "ec2" {
  source              = "../../modules"

  environment         = "prod"
  project_name        = "fastAPI_ProcMon"
  instance_type       = "t3.micro"
  root_volume_size    = 30
  subnet_id           = data.aws_subnets.default.ids[0]
  security_group_ids  = [module.security_group.aws_security_group.ec2.id]
  key_name            = "prod-fastapi-key"
}
