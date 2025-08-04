module "ec2" {
  source = "../../modules"

  environment         = "dev"
  project_name        = "fastAPI_ProcMon"
  instance_type       = "t3.micro"
  ssh_cidr_blocks     = ["31.13.163.243/32"]
  http_port           = 8000
  root_volume_size    = 30
  key_name            = "dev-fastapi-key"
}
