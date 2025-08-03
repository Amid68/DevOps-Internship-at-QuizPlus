module "security_group" {
  source              = "../../modules"

  project_name        = "fastAPI_ProcMon"
  environment         = "dev"
  ssh_cidr_blocks     = ["158.140.75.65/32"]
  http_port           = 8000
}
module "ec2" {
  source = "../../modules"

  environment         = "dev"
  project_name        = "fastAPI_ProcMon"
  instance_type       = "t3.micro"
  root_volume_size    = 30
  key_name            = "dev-fastapi-key"
}
