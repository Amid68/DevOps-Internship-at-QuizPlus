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

variable "http_port" {
  description = "HTTP port to allow"
  type        = number
  default     = 8000
}
