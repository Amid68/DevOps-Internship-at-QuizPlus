# Terraform Best Practices

## Project Organization and Structure

### Standard Project Layout

```
terraform-infrastructure/
├── README.md
├── .gitignore
├── .terraform-version          # tfenv version file
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── production/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── ec2/
│   └── rds/
├── shared/
│   ├── data.tf              # Common data sources
│   └── locals.tf            # Shared local values
└── scripts/
    ├── deploy.sh
    └── validate.sh
```

### File Naming Conventions

#### Core Configuration Files
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations
- `locals.tf` - Local value definitions
- `data.tf` - Data source definitions
- `versions.tf` - Provider version constraints

#### Environment-Specific Files
- `terraform.tfvars` - Variable values for environment
- `backend.tf` - Backend configuration
- `providers.tf` - Provider configurations

#### Module Files
- `README.md` - Module documentation
- `examples/` - Usage examples
- `tests/` - Module tests

### Directory Structure Best Practices

**Environment Separation:**
```
# Good: Separate directories per environment
environments/
├── dev/
├── staging/
└── production/

# Avoid: Single directory with workspace switching
```

**Module Organization:**
```
# Good: Logical grouping by functionality
modules/
├── networking/
│   ├── vpc/
│   ├── subnets/
│   └── security-groups/
├── compute/
│   ├── ec2/
│   ├── asg/
│   └── elb/
└── data/
    ├── rds/
    ├── elasticache/
    └── s3/
```

## Code Style and Formatting

### Terraform Formatting

**Always use `terraform fmt`:**
```bash
# Format all files
terraform fmt -recursive

# Check formatting in CI
terraform fmt -check -recursive
```

**Use consistent indentation:**
```hcl
# Good
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = var.instance_name
    Environment = var.environment
  }
}

# Avoid inconsistent spacing
resource "aws_instance" "web" {
ami           = var.ami_id
   instance_type = var.instance_type
  tags = {
Name        = var.instance_name
     Environment = var.environment
  }
}
```

### Naming Conventions

#### Resource Naming
```hcl
# Good: Descriptive and consistent
resource "aws_instance" "web_server" {
  # ...
}

resource "aws_security_group" "web_server_sg" {
  # ...
}

# Avoid: Generic or unclear names
resource "aws_instance" "server" {
  # ...
}

resource "aws_security_group" "sg" {
  # ...
}
```

#### Variable Naming
```hcl
# Good: Clear and descriptive
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "web_server_port" {
  description = "Port for web server traffic"
  type        = number
  default     = 80
}

# Avoid: Abbreviated or unclear names
variable "inst_type" {
  type    = string
  default = "t3.micro"
}
```

### Comments and Documentation

**Use comments for complex logic:**
```hcl
# Calculate subnet CIDR blocks for each availability zone
# using cidrsubnet function to avoid overlap
locals {
  # Split the VPC CIDR into /24 subnets
  # VPC: 10.0.0.0/16 -> Subnets: 10.0.1.0/24, 10.0.2.0/24, etc.
  public_subnet_cidrs = [
    for i in range(length(var.availability_zones)) :
    cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]

  private_subnet_cidrs = [
    for i in range(length(var.availability_zones)) :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
}
```

**Document variable purposes:**
```hcl
variable "instance_count" {
  description = <<-EOT
    Number of EC2 instances to create.
    Should be set to match the number of availability zones
    for high availability deployment.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

## Security Best Practices

### State File Security

**Use remote state with encryption:**
```hcl
terraform {
  backend "s3" {
    bucket         = "secure-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true                    # Enable encryption at rest
    dynamodb_table = "terraform-state-lock" # Enable state locking
    
    # Optional: Use KMS key for additional security
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

**Restrict state file access:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/TerraformRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::secure-terraform-state-bucket/*"
    }
  ]
}
```

### Sensitive Data Management

**Mark sensitive variables appropriately:**
```hcl
variable "database_password" {
  description = "Master password for RDS instance"
  type        = string
  sensitive   = true
}

variable "api_keys" {
  description = "API keys for external services"
  type        = map(string)
  sensitive   = true
}
```

**Use external secret management:**
```hcl
# Good: Reference secrets from external systems
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/master-password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
  # ...
}

# Avoid: Hard-coded secrets
resource "aws_db_instance" "main" {
  password = "hardcoded-password"  # Never do this!
  # ...
}
```

### IAM and Permissions

**Use least privilege principle:**
```hcl
# Good: Specific permissions for Terraform
data "aws_iam_policy_document" "terraform" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateInstance",
      "ec2:TerminateInstance",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

# Avoid: Overly broad permissions
data "aws_iam_policy_document" "terraform_bad" {
  statement {
    effect    = "Allow"
    actions   = ["*"]         # Too broad!
    resources = ["*"]
  }
}
```

**Use assume roles for cross-account access:**
```hcl
provider "aws" {
  alias = "security"
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformCrossAccountRole"
  }
}
```

## State Management Best Practices

### Backend Configuration

**Use separate state files for different environments:**
```hcl
# dev/backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "dev/infrastructure.tfstate"
    region = "us-west-2"
  }
}

# production/backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "production/infrastructure.tfstate"
    region = "us-west-2"
  }
}
```

**Use state locking:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "infrastructure.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"  # Prevents concurrent runs
  }
}
```

### State File Organization

**Separate state by blast radius:**
```
# Good: Separate critical infrastructure
core-infrastructure/     # VPC, subnets, security groups
├── networking.tfstate
└── security.tfstate

application-infrastructure/  # Applications, databases
├── web-app.tfstate
└── database.tfstate

# Avoid: Single large state file
monolithic/
└── everything.tfstate   # Too risky!
```

### State Operations

**Regular state backups:**
```bash
#!/bin/bash
# backup-state.sh
DATE=$(date +%Y%m%d_%H%M%S)
terraform state pull > "backups/terraform.tfstate.backup.${DATE}"
```

**Safe state modifications:**
```bash
# Always backup before state operations
terraform state pull > terraform.tfstate.backup

# Use terraform state commands instead of manual editing
terraform state mv old_resource new_resource
terraform state rm resource_to_remove
```

## Module Development Best Practices

### Module Structure

**Standard module layout:**
```
modules/vpc/
├── README.md           # Module documentation
├── main.tf            # Primary resources
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── versions.tf        # Provider requirements
├── examples/          # Usage examples
│   ├── basic/
│   └── complete/
└── tests/            # Module tests
    ├── unit/
    └── integration/
```

### Module Interface Design

**Clear variable definitions:**
```hcl
variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "The cidr_block value must be a valid CIDR block."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
```

**Comprehensive outputs:**
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
```

### Module Versioning

**Use semantic versioning:**
```hcl
# Use specific versions in production
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"  # Exact version
  # ...
}

# Use version constraints for flexibility
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14"  # Allow patch updates
  # ...
}
```

**Version your own modules:**
```bash
# Tag module releases
git tag v1.0.0
git push origin v1.0.0

# Reference tagged versions
module "my_module" {
  source = "git::https://github.com/my-org/terraform-modules.git//vpc?ref=v1.0.0"
  # ...
}
```

### Module Documentation

**Comprehensive README:**
```markdown
# VPC Module

This module creates a VPC with public and private subnets across multiple availability zones.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name               = "my-vpc"
  cidr_block            = "10.0.0.0/16"
  availability_zones    = ["us-west-2a", "us-west-2b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name tag for the VPC | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | IDs of the public subnets |
```

## CI/CD Integration

### Pipeline Structure

**GitLab CI example:**
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}/environments/production
  TF_IN_AUTOMATION: "true"

before_script:
  - cd ${TF_ROOT}
  - terraform init

validate:
  stage: validate
  script:
    - terraform fmt -check -recursive
    - terraform validate
    - tflint
  rules:
    - if: '$CI_MERGE_REQUEST_IID'

plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 1 week
  rules:
    - if: '$CI_MERGE_REQUEST_IID'

apply:
  stage: apply
  script:
    - terraform apply tfplan
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
  when: manual
  dependencies:
    - plan
```

**GitHub Actions example:**
```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    defaults:
      run:
        working-directory: ./environments/production

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Format
      run: terraform fmt -check -recursive
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -no-color
      if: github.event_name == 'pull_request'
    
    - name: Terraform Apply
      run: terraform apply -auto-approve
      if: github.ref == 'refs/heads/main'
```

### Pre-commit Hooks

**Configure pre-commit:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
      - id: terraform_checkov
```

**Install and use:**
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Testing Strategies

### Unit Testing

**Terratest example:**
```go
// test/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
        Vars: map[string]interface{}{
            "vpc_name":    "test-vpc",
            "cidr_block":  "10.0.0.0/16",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

### Integration Testing

**Kitchen Terraform:**
```yaml
# .kitchen.yml
driver:
  name: terraform

provisioner:
  name: terraform

verifier:
  name: terraform
  systems:
    - name: aws
      backend: aws

platforms:
  - name: aws

suites:
  - name: default
    driver:
      variables:
        vpc_name: test-vpc
        cidr_block: 10.0.0.0/16
    verifier:
      systems:
        - name: aws
          controls:
            - vpc_exists
            - subnets_created
```

### Validation Testing

**Custom validation:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "instance_count" {
  description = "Number of instances"
  type        = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

## Performance and Cost Optimization

### Resource Optimization

**Use appropriate instance types:**
```hcl
locals {
  # Environment-specific instance sizing
  instance_configs = {
    dev = {
      instance_type = "t3.micro"
      volume_size   = 20
    }
    staging = {
      instance_type = "t3.small"
      volume_size   = 30
    }
    production = {
      instance_type = "t3.medium"
      volume_size   = 50
    }
  }
  
  current_config = local.instance_configs[var.environment]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.current_config.instance_type

  root_block_device {
    volume_size = local.current_config.volume_size
    volume_type = "gp3"  # More cost-effective than gp2
  }
}
```

**Implement auto-scaling:**
```hcl
resource "aws_autoscaling_group" "web" {
  min_size         = var.environment == "production" ? 2 : 1
  max_size         = var.environment == "production" ? 10 : 3
  desired_capacity = var.environment == "production" ? 3 : 1
  
  # Use mixed instance types for cost optimization
  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage = 20
      spot_allocation_strategy = "diversified"
    }
    
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web.id
        version = "$Latest"
      }
      
      override {
        instance_type = "t3.medium"
      }
      override {
        instance_type = "t3.large"
      }
    }
  }
}
```

### State Performance

**Minimize state file size:**
```hcl
# Good: Use data sources for external resources
data "aws_vpc" "existing" {
  id = var.vpc_id
}

resource "aws_instance" "web" {
  subnet_id = data.aws_subnets.private.ids[0]
  # ...
}

# Avoid: Managing external resources unnecessarily
resource "aws_vpc" "imported" {
  # Don't manage VPCs you don't own
}
```

### Parallel Execution

**Use depends_on judiciously:**
```hcl
# Good: Let Terraform determine dependencies automatically
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id  # Implicit dependency
}

resource "aws_instance" "web" {
  vpc_security_group_ids = [aws_security_group.web.id]  # Implicit dependency
}

# Avoid: Unnecessary explicit dependencies
resource "aws_instance" "web" {
  depends_on = [aws_vpc.main]  # Usually unnecessary
}
```

## Collaboration and Team Practices

### Code Review Process

**Review checklist:**
- [ ] Terraform format (`terraform fmt`) applied
- [ ] Configuration validated (`terraform validate`)
- [ ] Security best practices followed
- [ ] State impact considered (blast radius)
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Variable descriptions complete
- [ ] Outputs documented

### Branch Protection

**Git workflow:**
```bash
# Feature branch workflow
git checkout -b feature/add-monitoring
# Make changes
git commit -m "Add CloudWatch monitoring for EC2 instances"
git push origin feature/add-monitoring
# Create pull request
```

**Branch protection rules:**
- Require pull request reviews
- Require status checks (CI/CD pipeline)
- Require branches to be up to date
- Restrict push to main branch

### Documentation Standards

**Maintain architecture documentation:**
```markdown
# Infrastructure Documentation

## Architecture Overview
[Diagram of infrastructure]

## Environments
- **Development**: Single AZ, minimal resources
- **Staging**: Multi-AZ, production-like
- **Production**: Multi-AZ, high availability

## Deployment Process
1. Create feature branch
2. Make changes and test locally
3. Create pull request
4. Review and approve
5. Merge to main
6. Automatic deployment via CI/CD

## Runbooks
- [Deployment Process](docs/deployment.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Emergency Procedures](docs/emergency.md)
```

### Team Standards

**Establish coding standards:**
```hcl
# Team standard: Always use these tags
locals {
  common_tags = {
    Environment   = var.environment
    Team         = var.team
    Project      = var.project
    ManagedBy    = "terraform"
    CreatedBy    = data.aws_caller_identity.current.user_id
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }
}

resource "aws_instance" "web" {
  # Always merge common tags
  tags = merge(local.common_tags, {
    Name = "web-server"
    Role = "web"
  })
}
```

## Troubleshooting and Debugging

### Common Issues and Solutions

#### State Lock Issues
```bash
# Check for existing locks
terraform state list

# Force unlock (use with extreme caution)
terraform force-unlock LOCK_ID

# Prevention: Always use proper CI/CD pipelines
```

#### Import Existing Resources
```bash
# Find the resource ID
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'

# Import the resource
terraform import aws_instance.web i-1234567890abcdef0

# Verify the import
terraform plan
```

#### Provider Version Conflicts
```hcl
# Lock provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.10.0"  # Exact version to avoid conflicts
    }
  }
}
```

### Debugging Techniques

**Enable detailed logging:**
```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run with logging
terraform apply

# Filter logs
grep "aws_instance.web" terraform.log
```

**Use terraform console for testing:**
```bash
terraform console

# Test expressions
> var.instance_type
> local.common_tags
> aws_instance.web.public_ip
```

**Validate and check formatting:**
```bash
# Comprehensive validation
terraform fmt -check -recursive
terraform validate
terraform plan -detailed-exitcode

# External tools
tflint                    # Linting
tfsec                     # Security scanning
checkov -f main.tf        # Policy checking
```

### Error Recovery

**State corruption recovery:**
```bash
# Backup current state
terraform state pull > backup.tfstate

# Refresh state from infrastructure
terraform refresh

# If needed, restore from backup
terraform state push backup.tfstate
```

**Resource drift detection:**
```bash
# Detect configuration drift
terraform plan -refresh-only

# Show current vs desired state
terraform show -json | jq '.values.root_module.resources'
```

## Version Control Best Practices

### .gitignore Configuration

```gitignore
# .gitignore for Terraform projects

# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
*tfplan*

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore Mac .DS_Store files
.DS_Store

# Ignore editor files
*.swp
*.swo
*~

# Ignore log files
*.log
```

### Commit Message Standards

**Use conventional commits:**
```bash
# Feature additions
git commit -m "feat(vpc): add support for multiple availability zones"

# Bug fixes
git commit -m "fix(security-group): correct ingress rule for SSH access"

# Documentation
git commit -m "docs(readme): update module usage examples"

# Refactoring
git commit -m "refactor(modules): reorganize VPC module structure"

# Breaking changes
git commit -m "feat(rds)!: change default engine version to 14.6"
```

### Release Management

**Semantic versioning for modules:**
```bash
# Major version (breaking changes)
git tag v2.0.0

# Minor version (new features)
git tag v1.1.0

# Patch version (bug fixes)
git tag v1.0.1

# Push tags
git push origin --tags
```

This comprehensive guide covers the essential best practices for Terraform development, from project organization to production deployment. Following these practices will help ensure your infrastructure code is maintainable, secure, and scalable.
