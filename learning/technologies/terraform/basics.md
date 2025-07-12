# Terraform Basics

## What is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp that allows you to define and provision infrastructure using a declarative configuration language called HashiCorp Configuration Language (HCL).

### Key Characteristics
- **Declarative:** You describe the desired end state, not the steps to get there
- **Provider-based:** Works with multiple cloud providers (AWS, Azure, GCP, etc.)
- **State Management:** Tracks the current state of your infrastructure
- **Plan and Apply:** Shows you what will change before making changes
- **Open Source:** Free to use with enterprise features available

### Infrastructure as Code Benefits
- **Version Control:** Infrastructure configurations can be versioned and tracked
- **Reproducible:** Create identical environments consistently
- **Collaborative:** Team members can review and collaborate on infrastructure changes
- **Auditable:** Clear history of who changed what and when
- **Automated:** Integrate with CI/CD pipelines for automated deployments

## Core Terraform Concepts

### 1. Configuration Files
Terraform configurations are written in `.tf` files using HCL syntax.

**Common file naming conventions:**
- `main.tf` - Primary configuration
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output value definitions
- `terraform.tf` - Terraform and provider configuration
- `locals.tf` - Local value definitions

### 2. Providers
Providers are plugins that enable Terraform to interact with cloud platforms, SaaS providers, and other APIs.

```hcl
# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

### 3. Resources
Resources are the most important element in Terraform. They represent infrastructure objects like virtual machines, networks, or databases.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```

### 4. Data Sources
Data sources allow you to fetch information from existing infrastructure or external sources.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

### 5. Variables
Variables allow you to parameterize your configurations and make them reusable.

```hcl
variable "instance_type" {
  description = "Type of EC2 instance to launch"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}
```

### 6. Outputs
Outputs expose information about your infrastructure for use by other configurations or for display.

```hcl
output "instance_ip_addr" {
  value = aws_instance.web.private_ip
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
}
```

## HCL Syntax Fundamentals

### Basic Structure
```hcl
<BLOCK_TYPE> "<BLOCK_LABEL>" "<BLOCK_LABEL>" {
  # Block body
  <IDENTIFIER> = <EXPRESSION> # Argument
}
```

### Comments
```hcl
# Single line comment

/*
Multi-line
comment
*/
```

### Data Types

#### Primitive Types
```hcl
# String
variable "name" {
  type    = string
  default = "example"
}

# Number
variable "port" {
  type    = number
  default = 8080
}

# Boolean
variable "enable_monitoring" {
  type    = bool
  default = true
}
```

#### Complex Types
```hcl
# List
variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# Map
variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Team        = "platform"
  }
}

# Object
variable "server_config" {
  type = object({
    instance_type = string
    disk_size     = number
    monitoring    = bool
  })
  default = {
    instance_type = "t2.micro"
    disk_size     = 20
    monitoring    = true
  }
}
```

### Expressions and Functions

#### String Interpolation
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = "${var.environment}-web-server"
  }
}
```

#### Conditionals
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.environment == "production" ? "t3.large" : "t2.micro"
  
  monitoring = var.environment == "production" ? true : false
}
```

#### For Expressions
```hcl
locals {
  # Create a list of instance names
  instance_names = [for i in range(var.instance_count) : "${var.environment}-web-${i + 1}"]
  
  # Create a map of tags
  common_tags = {
    for k, v in var.tags : k => upper(v)
  }
}
```

## Essential Terraform Commands

### Initialize and Setup

#### terraform init
Initializes a Terraform working directory and downloads required providers.

```bash
# Initialize the current directory
terraform init

# Initialize and upgrade providers
terraform init -upgrade

# Initialize with backend configuration
terraform init -backend-config="bucket=my-terraform-state"
```

#### terraform version
Check Terraform and provider versions.

```bash
# Show Terraform version
terraform version

# Show detailed version information
terraform version -json
```

### Planning and Applying Changes

#### terraform plan
Creates an execution plan showing what Terraform will do.

```bash
# Generate and show execution plan
terraform plan

# Save plan to a file
terraform plan -out=tfplan

# Plan with variable file
terraform plan -var-file="production.tfvars"

# Plan targeting specific resources
terraform plan -target=aws_instance.web
```

#### terraform apply
Applies changes to reach the desired state.

```bash
# Apply changes (will prompt for confirmation)
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply without confirmation prompt
terraform apply -auto-approve

# Apply with variable values
terraform apply -var="instance_type=t3.large"
```

### State Management

#### terraform show
Displays the current state or a saved plan.

```bash
# Show current state
terraform show

# Show saved plan
terraform show tfplan

# Output in JSON format
terraform show -json
```

#### terraform state
Advanced state management commands.

```bash
# List resources in state
terraform state list

# Show specific resource details
terraform state show aws_instance.web

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.web

# Import existing resource into state
terraform import aws_instance.web i-1234567890abcdef0
```

### Destroying Infrastructure

#### terraform destroy
Destroys all managed infrastructure.

```bash
# Destroy all resources (will prompt for confirmation)
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resources
terraform destroy -target=aws_instance.web
```

### Validation and Formatting

#### terraform validate
Validates the configuration files.

```bash
# Validate configuration
terraform validate

# Validate with JSON output
terraform validate -json
```

#### terraform fmt
Formats configuration files to canonical format.

```bash
# Format files in current directory
terraform fmt

# Format files recursively
terraform fmt -recursive

# Check if files are formatted (returns exit code)
terraform fmt -check
```

## Working with Variables

### Defining Variables

```hcl
# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}
```

### Setting Variable Values

#### Command Line
```bash
# Single variable
terraform apply -var="region=us-east-1"

# Multiple variables
terraform apply -var="region=us-east-1" -var="instance_count=3"
```

#### Variable Files (.tfvars)
```hcl
# production.tfvars
region         = "us-west-2"
instance_count = 3
environment    = "production"

tags = {
  Environment = "production"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

```bash
# Apply with variable file
terraform apply -var-file="production.tfvars"
```

#### Environment Variables
```bash
# Set environment variables (TF_VAR_ prefix)
export TF_VAR_region="us-west-2"
export TF_VAR_instance_count=3

terraform apply
```

#### terraform.tfvars (Automatic)
Terraform automatically loads `terraform.tfvars` and `*.auto.tfvars` files.

```hcl
# terraform.tfvars
region      = "us-west-2"
environment = "development"
```

### Variable Precedence (highest to lowest)
1. Command line `-var` flags
2. `*.auto.tfvars` files (in alphabetical order)
3. `terraform.tfvars` file
4. Environment variables (`TF_VAR_*`)
5. Default values in variable declarations

## Local Values

Local values assign names to expressions and can be used multiple times within a configuration.

```hcl
locals {
  # Simple local values
  service_name = "web-app"
  owner        = "platform-team"
  
  # Computed local values
  common_tags = {
    Name        = local.service_name
    Environment = var.environment
    Owner       = local.owner
    ManagedBy   = "terraform"
  }
  
  # Complex expressions
  instance_name_prefix = "${var.environment}-${local.service_name}"
  
  # Conditional logic
  instance_type = var.environment == "production" ? "t3.large" : "t2.micro"
  
  # List processing
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  
  tags = merge(local.common_tags, {
    Name = "${local.instance_name_prefix}-${count.index + 1}"
  })
}
```

## Resource Dependencies

### Implicit Dependencies
Terraform automatically creates dependencies based on resource references.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Implicit dependency on VPC
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  ami       = data.aws_ami.ubuntu.id
  subnet_id = aws_subnet.public.id  # Implicit dependency on subnet
}
```

### Explicit Dependencies
Use `depends_on` when Terraform can't automatically detect dependencies.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  
  # Explicit dependency
  depends_on = [aws_security_group.web]
}

resource "aws_security_group" "web" {
  name = "web-sg"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Meta-Arguments

### count
Create multiple instances of a resource.

```hcl
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "web-${count.index + 1}"
  }
}

# Reference specific instance
output "first_instance_ip" {
  value = aws_instance.web[0].private_ip
}

# Reference all instances
output "all_instance_ips" {
  value = aws_instance.web[*].private_ip
}
```

### for_each
Create multiple instances based on a map or set of strings.

```hcl
variable "instances" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
  default = {
    web = {
      instance_type = "t2.micro"
      ami           = "ami-0c02fb55956c7d316"
    }
    app = {
      instance_type = "t2.small"
      ami           = "ami-0c02fb55956c7d316"
    }
  }
}

resource "aws_instance" "servers" {
  for_each      = var.instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  
  tags = {
    Name = each.key
    Type = each.key
  }
}

# Reference specific instance
output "web_instance_ip" {
  value = aws_instance.servers["web"].private_ip
}
```

### lifecycle
Control resource lifecycle behavior.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  lifecycle {
    # Prevent destruction of this resource
    prevent_destroy = true
    
    # Create new resource before destroying old one
    create_before_destroy = true
    
    # Ignore changes to specific attributes
    ignore_changes = [ami, user_data]
  }
}
```

## Basic Project Structure

### Simple Project
```
simple-project/
├── main.tf                 # Primary configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars        # Variable values
└── README.md              # Documentation
```

### Organized Project
```
organized-project/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── locals.tf               # Local values
├── data.tf                 # Data sources
├── terraform.tf            # Terraform/provider config
├── versions.tf             # Version constraints
├── environments/           # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── production.tfvars
└── README.md              # Documentation
```

## Common Terraform Workflow

### 1. Write Configuration
Create your `.tf` files with the desired infrastructure.

### 2. Initialize
```bash
terraform init
```

### 3. Plan
```bash
terraform plan -var-file="environment.tfvars"
```

### 4. Review
Carefully review the planned changes.

### 5. Apply
```bash
terraform apply -var-file="environment.tfvars"
```

### 6. Verify
Check that the infrastructure was created correctly.

### 7. Version Control
Commit your configuration files to version control.

## Error Handling and Debugging

### Common Error Types

#### Configuration Errors
```bash
# Syntax errors
terraform validate
terraform fmt -check

# Check configuration
terraform plan
```

#### State Conflicts
```bash
# Refresh state
terraform refresh

# Check state
terraform state list
terraform state show resource_name
```

#### Provider Issues
```bash
# Update providers
terraform init -upgrade

# Check provider configuration
terraform providers
```

### Debugging Tips

#### Enable Logging
```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

terraform apply
```

#### Use terraform console
```bash
# Interactive console for testing expressions
terraform console

# Test expressions
> var.instance_type
> local.common_tags
> aws_instance.web.public_ip
```

## Getting Help

### Built-in Help
```bash
# General help
terraform -help

# Command-specific help
terraform plan -help
terraform apply -help

# Provider documentation
terraform providers schema -json
```

### Useful Resources
- **Terraform Documentation:** https://terraform.io/docs
- **Provider Registry:** https://registry.terraform.io
- **Community Forum:** https://discuss.hashicorp.com/c/terraform-core
- **GitHub Issues:** https://github.com/hashicorp/terraform/issues

## Next Steps

After mastering these basics, you should explore:
1. **Modules** - Reusable configuration components
2. **State Management** - Remote state and locking
3. **Workspaces** - Managing multiple environments
4. **Advanced Functions** - Built-in functions and expressions
5. **Provider Configuration** - Multiple providers and aliases
6. **CI/CD Integration** - Automating Terraform workflows
