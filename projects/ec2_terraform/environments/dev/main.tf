module "ec2" {
  source = "../../modules"

  environment         = "dev"
  project_name        = "fastAPI_ProcMon"
  instance_type       = "t3.micro"
  ssh_cidr_blocks     = ["46.60.116.187/32"]
  root_volume_size    = 30
  key_name            = "dev-fastapi-key"

  domain_name         = "ameed.xyz"
  dns_ttl             = 60
}
