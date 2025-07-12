# Terraform Advanced Concepts

## Modules

Modules are containers for multiple resources that are used together. They allow you to create reusable components and organize your Terraform configurations effectively.

### What are Modules?

A module is a collection of `.tf` files kept together in a directory. Every Terraform configuration has at least one module, known as the **root module**, which consists of the resources defined in the `.tf` files in the main working directory.

### Module Structure

```
modules/
└── vpc/
    ├── main.tf              # Resources
    ├── variables.tf         # Input variables
    ├── outputs.tf          # Output values
    ├── versions.tf         # Provider requirements
    └── README.md           # Documentation
```

### Creating a Module

#### Module: VPC (`modules/vpc/main.tf`)
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-private-${count.index + 1}"
    Type = "private"
  })
}

resource "aws_internet_gateway" "main" {
  count  = length(var.public_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}
```

#### Module Variables (`modules/vpc/variables.tf`)
```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "The cidr_block value must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
```

#### Module Outputs (`modules/vpc/outputs.tf`)
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].id : null
}
```

### Using Modules

#### Root Module (`main.tf`)
```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name               = "production-vpc"
  cidr_block            = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones    = ["us-west-2a", "us-west-2b"]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Use module outputs
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = {
    Name = "web-server"
  }
}
```

### Module Sources

#### Local Modules
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ...
}
```

#### Git Repository
```hcl
module "vpc" {
  source = "git::https://github.com/your-org/terraform-modules.git//vpc?ref=v1.0.0"
  # ...
}
```

#### Terraform Registry
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  # ...
}
```

#### HTTP URLs
```hcl
module "vpc" {
  source = "https://example.com/terraform-modules/vpc.zip"
  # ...
}
```

### Module Versioning

#### Using Git Tags
```hcl
module "vpc" {
  source = "git::https://github.com/your-org/terraform-modules.git//vpc?ref=v2.1.0"
  # ...
}
```

#### Using Registry Versions
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"  # Allow patch updates
  # version = ">= 3.14.0, < 4.0.0"  # More specific
  # ...
}
```

## State Management

### Understanding Terraform State

Terraform state is a mapping between your configuration and the real-world resources. It's stored in a file called `terraform.tfstate`.

#### Local State (Default)
```
project/
├── main.tf
├── terraform.tfstate      # State file
└── terraform.tfstate.backup
```

#### State Contents
```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 1,
  "lineage": "12345678-1234-1234-1234-123456789012",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-0c02fb55956c7d316",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

### Remote State Backends

#### S3 Backend
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "production/infrastructure.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### Azure Storage Backend
```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "mystorageaccount"
    container_name       = "tfstate"
    key                 = "production.terraform.tfstate"
  }
}
```

#### Google Cloud Storage Backend
```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "terraform/state"
  }
}
```

#### Terraform Cloud Backend
```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      name = "production-infrastructure"
    }
  }
}
```

### State Locking

State locking prevents multiple users from running Terraform simultaneously and corrupting the state.

#### DynamoDB for S3 Backend
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "production/infrastructure.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Enables locking
  }
}
```

#### Manual Lock Override
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### State Operations

#### Importing Existing Resources
```bash
# Import existing AWS instance
terraform import aws_instance.web i-1234567890abcdef0

# Import with module
terraform import module.vpc.aws_vpc.main vpc-12345678
```

#### Moving Resources in State
```bash
# Rename resource in state
terraform state mv aws_instance.web aws_instance.web_server

# Move resource to module
terraform state mv aws_instance.web module.web.aws_instance.main

# Move resource between modules
terraform state mv module.old.aws_instance.web module.new.aws_instance.web
```

#### Removing Resources from State
```bash
# Remove resource from state (doesn't destroy actual resource)
terraform state rm aws_instance.web

# Remove entire module
terraform state rm module.vpc
```

#### State Inspection
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Show all state
terraform show

# Output state in JSON
terraform show -json
```

### State File Management

#### Backup and Recovery
```bash
# Pull remote state to local file
terraform state pull > backup.tfstate

# Push local state to remote
terraform state push backup.tfstate
```

#### State Refresh
```bash
# Refresh state to match real infrastructure
terraform refresh

# Plan with refresh
terraform plan -refresh-only
```

## Workspaces

Workspaces allow you to manage multiple environments with the same configuration.

### Basic Workspace Operations

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new development

# Switch to workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete development
```

### Using Workspaces in Configuration

```hcl
locals {
  # Environment-specific configurations
  workspace_configs = {
    default = {
      instance_type = "t2.micro"
      instance_count = 1
    }
    development = {
      instance_type = "t2.micro"
      instance_count = 1
    }
    staging = {
      instance_type = "t2.small"
      instance_count = 2
    }
    production = {
      instance_type = "t3.medium"
      instance_count = 3
    }
  }

  current_config = local.workspace_configs[terraform.workspace]
}

resource "aws_instance" "web" {
  count         = local.current_config.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_config.instance_type

  tags = {
    Name        = "${terraform.workspace}-web-${count.index + 1}"
    Environment = terraform.workspace
  }
}
```

### Workspace-Specific State Files

Each workspace maintains its own state file:
```
terraform.tfstate.d/
├── development/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── production/
    └── terraform.tfstate
```

## Advanced Functions and Expressions

### String Functions

```hcl
locals {
  # String manipulation
  upper_name    = upper(var.project_name)           # "PROJECT"
  lower_name    = lower(var.project_name)           # "project"
  title_name    = title(var.project_name)           # "Project"
  
  # String formatting
  padded_number = format("%03d", var.instance_number) # "001"
  formatted_msg = format("Hello %s, you have %d messages", var.username, var.message_count)
  
  # String operations
  trimmed      = trimspace("  hello world  ")       # "hello world"
  replaced     = replace(var.text, "old", "new")
  split_list   = split(",", "a,b,c")                # ["a", "b", "c"]
  joined       = join("-", ["a", "b", "c"])         # "a-b-c"
  
  # Substring operations
  substring    = substr("hello world", 0, 5)        # "hello"
  
  # Regular expressions
  regex_match  = regex("[0-9]+", "abc123def")       # "123"
  regex_all    = regexall("[0-9]+", "a1b2c3")      # ["1", "2", "3"]
}
```

### Collection Functions

```hcl
locals {
  list_example = ["a", "b", "c", "a"]
  map_example  = {
    key1 = "value1"
    key2 = "value2"
  }
  
  # List operations
  list_length    = length(local.list_example)        # 4
  reversed_list  = reverse(local.list_example)       # ["a", "c", "b", "a"]
  sorted_list    = sort(local.list_example)          # ["a", "a", "b", "c"]
  unique_list    = distinct(local.list_example)      # ["a", "b", "c"]
  contains_check = contains(local.list_example, "b") # true
  
  # List slicing
  slice_result   = slice(local.list_example, 1, 3)   # ["b", "c"]
  
  # Element access
  first_element  = element(local.list_example, 0)    # "a"
  safe_element   = try(element(local.list_example, 10), "default") # "default"
  
  # Map operations
  map_keys       = keys(local.map_example)           # ["key1", "key2"]
  map_values     = values(local.map_example)         # ["value1", "value2"]
  
  # Merging
  merged_map = merge(local.map_example, {
    key3 = "value3"
  })
}
```

### Date and Time Functions

```hcl
locals {
  current_time   = timestamp()                       # "2023-07-12T14:30:00Z"
  formatted_time = formatdate("YYYY-MM-DD", timestamp())
  
  # Time arithmetic
  future_time = timeadd(timestamp(), "24h")
  
  # RFC 3339 format
  rfc3339_time = formatdate("RFC3339", timestamp())
}
```

### Encoding Functions

```hcl
locals {
  # Base64
  encoded_string = base64encode("hello world")
  decoded_string = base64decode(local.encoded_string)
  
  # JSON
  json_string    = jsonencode({
    name = "example"
    age  = 30
  })
  parsed_json    = jsondecode(local.json_string)
  
  # URL encoding
  url_encoded    = urlencode("hello world!")         # "hello%20world%21"
}
```

### Conditional and Logical Functions

```hcl
locals {
  # Conditional
  result = var.environment == "production" ? "prod-config" : "dev-config"
  
  # Null checking
  safe_value = coalesce(var.optional_value, "default")
  
  # Try function for error handling
  safe_operation = try(
    var.complex_object.nested.value,
    "fallback_value"
  )
  
  # Type checking
  is_string = can(var.value == "string")
  is_number = can(var.value + 1)
}
```

## Dynamic Blocks

Dynamic blocks allow you to dynamically construct repeatable nested blocks.

### Basic Dynamic Block

```hcl
variable "security_group_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.security_group_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}
```

### Advanced Dynamic Blocks

```hcl
variable "ebs_block_devices" {
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
    encrypted   = bool
    iops        = optional(number)
  }))
  default = []
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
      encrypted   = ebs_block_device.value.encrypted
      iops        = ebs_block_device.value.volume_type == "gp3" ? ebs_block_device.value.iops : null
    }
  }
}
```

### Nested Dynamic Blocks

```hcl
variable "load_balancer_config" {
  type = object({
    listeners = list(object({
      port     = number
      protocol = string
      rules = list(object({
        priority = number
        actions = list(object({
          type             = string
          target_group_arn = string
        }))
        conditions = list(object({
          field  = string
          values = list(string)
        }))
      }))
    }))
  })
}

resource "aws_lb_listener" "web" {
  for_each = {
    for idx, listener in var.load_balancer_config.listeners : idx => listener
  }

  load_balancer_arn = aws_lb.web.arn
  port              = each.value.port
  protocol          = each.value.protocol

  dynamic "default_action" {
    for_each = [1]  # Single default action
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

resource "aws_lb_listener_rule" "web" {
  for_each = {
    for rule_key, rule in flatten([
      for listener_idx, listener in var.load_balancer_config.listeners : [
        for rule_idx, rule in listener.rules : {
          key         = "${listener_idx}-${rule_idx}"
          listener_idx = listener_idx
          rule        = rule
        }
      ]
    ]) : rule.key => rule
  }

  listener_arn = aws_lb_listener.web[each.value.listener_idx].arn
  priority     = each.value.rule.priority

  dynamic "action" {
    for_each = each.value.rule.actions
    content {
      type             = action.value.type
      target_group_arn = action.value.target_group_arn
    }
  }

  dynamic "condition" {
    for_each = each.value.rule.conditions
    content {
      dynamic "path_pattern" {
        for_each = condition.value.field == "path-pattern" ? [1] : []
        content {
          values = condition.value.values
        }
      }

      dynamic "host_header" {
        for_each = condition.value.field == "host-header" ? [1] : []
        content {
          values = condition.value.values
        }
      }
    }
  }
}
```

## Provisioners

Provisioners are used to execute scripts on local or remote machines as part of resource creation or destruction.

### Types of Provisioners

#### File Provisioner
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web.key_name

  provisioner "file" {
    source      = "app.conf"
    destination = "/tmp/app.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

#### Remote-exec Provisioner
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

#### Local-exec Provisioner
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} is being destroyed' >> destroy_log.txt"
  }
}
```

### Provisioner Connections

#### SSH Connection
```hcl
connection {
  type        = "ssh"
  user        = "ubuntu"
  private_key = file("~/.ssh/id_rsa")
  host        = self.public_ip
  port        = 22
  timeout     = "5m"
  
  # Optional: Bastion host
  bastion_host        = "bastion.example.com"
  bastion_user        = "bastion_user"
  bastion_private_key = file("~/.ssh/bastion_key")
}
```

#### WinRM Connection
```hcl
connection {
  type     = "winrm"
  user     = "Administrator"
  password = var.admin_password
  host     = self.public_ip
  port     = 5985
  https    = false
  timeout  = "10m"
}
```

## Provider Configuration

### Multiple Provider Configurations

```hcl
# Default provider
provider "aws" {
  region = "us-west-2"
}

# Additional provider with alias
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

# Use specific provider
resource "aws_instance" "west" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  # Uses default provider (us-west-2)
}

resource "aws_instance" "east" {
  provider      = aws.east
  ami           = data.aws_ami.ubuntu_east.id
  instance_type = "t2.micro"
  # Uses aliased provider (us-east-1)
}
```

### Provider Configuration with Variables

```hcl
variable "aws_regions" {
  type = map(object({
    region = string
    profile = string
  }))
  default = {
    primary = {
      region  = "us-west-2"
      profile = "primary"
    }
    secondary = {
      region  = "us-east-1"
      profile = "secondary"
    }
  }
}

provider "aws" {
  region  = var.aws_regions.primary.region
  profile = var.aws_regions.primary.profile
}

provider "aws" {
  alias   = "secondary"
  region  = var.aws_regions.secondary.region
  profile = var.aws_regions.secondary.profile
}
```

### Provider Requirements

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}
```

## Data Sources

### Advanced Data Source Usage

```hcl
# Get latest AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get caller identity
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Get VPC by tags
data "aws_vpc" "main" {
  tags = {
    Environment = var.environment
    Name        = "main-vpc"
  }
}

# Get subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Type = "private"
  }
}

# Use data in resources
resource "aws_instance" "web" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_id         = data.aws_subnets.private.ids[0]

  tags = {
    Owner      = data.aws_caller_identity.current.user_id
    Region     = data.aws_region.current.name
    LaunchedBy = "terraform"
  }
}
```

### External Data Sources

```hcl
# External program data source
data "external" "git_commit" {
  program = ["bash", "-c", "echo '{\"commit\": \"'$(git rev-parse HEAD)'\"}'"]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    GitCommit = data.external.git_commit.result.commit
  }
}
```

### HTTP Data Source

```hcl
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
  
  request_headers = {
    Accept = "text/plain"
  }
}

resource "aws_security_group" "web" {
  name = "web-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
}
```

## Terraform Settings and Experiments

### Terraform Block Configuration

```hcl
terraform {
  # Specify required Terraform version
  required_version = ">= 1.0, < 2.0"

  # Required providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "infrastructure.tfstate"
    region = "us-west-2"
  }

  # Enable experiments (use with caution)
  experiments = [
    # Example: variable_validation
  ]
}
```

### Advanced Variable Validation

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      can(regex("^[A-Za-z][A-Za-z0-9-_]*$", tag_key))
    ])
    error_message = "Tag keys must start with a letter and contain only alphanumeric characters, hyphens, and underscores."
  }

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      length(tag_value) <= 256
    ])
    error_message = "Tag values must be 256 characters or less."
  }
}

variable "cidr_blocks" {
  description = "List of CIDR blocks"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.cidr_blocks :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }

  validation {
    condition = length(var.cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified."
  }
}
```

### Sensitive Variables and Outputs

```hcl
variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "main" {
  identifier = "main-database"
  password   = var.database_password
  # ... other configuration
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true
}
```

This covers the major advanced Terraform concepts. These topics build upon the basics and are essential for managing complex infrastructure at scale.
