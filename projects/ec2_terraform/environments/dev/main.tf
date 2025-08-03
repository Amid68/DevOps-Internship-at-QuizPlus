module "security_group" {
  source = "../../modules"

  # Security group variables
  sg_environment      = "dev"
  vpc_id              = data.aws_vpc.default.id
  ssh_cidr_blocks     = ["158.140.75.65/32"]
  http_port           = 8000
  
  # Required EC2 variables (even though we don't use EC2 resource)
  environment         = "dev"
  project_name        = "fastAPI_ProcMon"
  subnet_id           = data.aws_subnets.default.ids[0]
  security_group_ids  = []  # Empty since we're creating the SG
}

module "ec2" {
  source = "../../modules"

  # EC2 variables
  environment         = "dev"
  project_name        = "fastAPI_ProcMon"
  instance_type       = "t3.micro"
  root_volume_size    = 30
  subnet_id           = data.aws_subnets.default.ids[0]
  security_group_ids  = [module.security_group.security_group_id]
  key_name            = "dev-fastapi-key"
  
  # Required security group variables (even though we don't use SG resource)
  sg_environment      = "dev"
  vpc_id              = data.aws_vpc.default.id
  ssh_cidr_blocks     = ["158.140.75.65/32"]
  http_port           = 8000
}
