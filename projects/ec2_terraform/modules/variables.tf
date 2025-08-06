variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  default     = null
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_port" {
  description = "HTTP port to allow"
  type        = number
  default     = 8000
}

variable "manage_dns" {
  description = "Whether to manage DNS records"
  type = bool
  default = false
}

variable "domain_name" {
  description = "Domain name for Route53"
  type = string
  default = ""
}

variable "subdomain" {
  description = "Subdomain prefix"
  type = string
  default = ""
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone"
  type = bool
  default = false
}

variable "existing_zone_id" {
  description = "Existing Route53 hosted zone ID"
  type = string
  default = ""
}

variable "dns_ttl" {
  description = "TTL for DNS records in seconds"
  type = number
  default = 300
}

variable "create_www_records" {
  description = "Whether to create a www CNAME record"
  type = bool
  default = false
}
