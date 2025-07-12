# Terraform Outputs

## What are Output Values?

Output values in Terraform make information about your infrastructure available for various purposes, similar to return values in programming languages. They provide a way for Terraform to expose specific attributes of resources, allowing you to retrieve and display certain data from your infrastructure.

### Key Characteristics
- **Data Exposure:** Allow you to retrieve and display data from your infrastructure
- **Command Line Access:** Make information available on the command line after operations
- **Module Integration:** Enable data sharing between different Terraform configurations
- **State Persistence:** Values are stored in the Terraform state file
- **Computed at Apply:** Only calculated and displayed when `terraform apply` runs successfully

### In Modules Context
In modules, output variables serve as the return values of a Terraform module that can be consumed by other configurations, particularly by the parent module that calls it. They allow you to pass information about infrastructure components defined within a module to other parts of your overall configuration.

## Why Use Outputs in Modules?

### 1. Information Exposure
- **Encapsulation:** Modules encapsulate groups of resources
- **Controlled Access:** Outputs provide the only supported way for users of a module to get information about the resources configured by that module
- **Clear Interface:** Create a well-defined interface for the module's consumers
- **Abstraction:** Hide internal complexity while exposing necessary information

### 2. Inter-Module Communication
- **Parent-Child Communication:** Child modules can use outputs to expose a subset of their resource attributes to parent modules
- **Data Sharing:** Enable controlled data flow between different modules
- **Dependency Management:** Establish clear relationships between modules
- **Loose Coupling:** Modules remain independent while sharing necessary information

### 3. CLI Display
- **User Feedback:** Outputs in a root module can be configured to print specific values to the command-line interface
- **Post-Apply Information:** Display important information after a `terraform apply` operation
- **Deployment Summaries:** Show key details about created infrastructure
- **Troubleshooting:** Provide quick access to important resource attributes

### 4. Remote State Referencing
- **Cross-Configuration Access:** Outputs from a root module can be accessed by other Terraform configurations through a `terraform_remote_state` data source
- **State Separation:** Useful when different parts of your infrastructure are managed by separate Terraform configurations and state files
- **Information Sharing:** Enable controlled data sharing between independent Terraform projects
- **Environment Coordination:** Facilitate communication between different environments or teams

## Declaring Output Values

### Basic Syntax
Each output value within a module must be declared using an `output` block. These declarations are typically placed in an `outputs.tf` file within the module's directory.

```hcl
output "output_name" {
  value = expression
}
```

### Key Components
- **Label:** The identifier immediately after the `output` keyword defines the output's name (must be a valid identifier)
- **Value:** The `value` argument is required and takes an expression whose result will be the value of the output
- **Expression Types:** Can reference resource attributes, local values, or input variables defined within the module

### Basic Examples

```hcl
# Simple resource attribute output
output "instance_ip" {
  value = aws_instance.web.public_ip
}

# Multiple values using object
output "instance_info" {
  value = {
    id         = aws_instance.web.id
    public_ip  = aws_instance.web.public_ip
    private_ip = aws_instance.web.private_ip
  }
}

# List of values
output "instance_ids" {
  value = aws_instance.web[*].id
}

# Computed expression
output "instance_url" {
  value = "https://${aws_instance.web.public_ip}:8080"
}
```

### Important Note
Outputs are only computed and displayed when Terraform successfully applies your infrastructure changes (`terraform apply`). The `terraform plan` command will not render outputs, as the actual values may not be known until resources are created.

## Optional Arguments for Output Declarations

### 1. description
**Purpose:** Provides documentation about the purpose and type of value expected.

```hcl
output "vpc_id" {
  description = "The ID of the VPC created for the application environment"
  value       = aws_vpc.main.id
}

output "database_endpoint" {
  description = "RDS instance connection endpoint for application configuration"
  value       = aws_db_instance.main.endpoint
}
```

### 2. sensitive
**Purpose:** Prevents Terraform from displaying the value in command-line output of `terraform plan` and `terraform apply`.

**Use cases:** Passwords, API keys, secret tokens, private keys

```hcl
output "database_password" {
  description = "Master password for RDS instance"
  value       = aws_db_instance.main.password
  sensitive   = true
}

output "api_key" {
  description = "API key for external service integration"
  value       = random_password.api_key.result
  sensitive   = true
}
```

**Note:** Sensitive outputs are still stored in the state file in plain text. Use additional encryption for state files containing sensitive data.

### 3. ephemeral
**Purpose:** Allows value to be passed between modules during a Terraform run but prevents it from being persisted to state or plan files.

**Use cases:** 
- Short-lived tokens
- Session IDs
- Transient data that shouldn't be stored

**Limitations:** Cannot be declared in root modules (only in child modules)

```hcl
output "session_token" {
  description = "Temporary session token for API access"
  value       = local.temp_session_token
  ephemeral   = true
}
```

### 4. depends_on
**Purpose:** Creates explicit dependencies for an output value in rare cases where Terraform cannot implicitly determine the correct order of operations.

**Usage:** Should be used as a last resort when implicit dependencies are insufficient

```hcl
output "cluster_ready" {
  description = "Indicates when cluster is fully configured"
  value       = "ready"
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    kubernetes_config_map.aws_auth
  ]
}
```

## Accessing Child Module Outputs

### Syntax
In a parent module, outputs from child modules are accessed using the syntax:
```hcl
module.<MODULE_NAME>.<OUTPUT_NAME>
```

### Example Structure
```
project/
├── main.tf
├── outputs.tf
└── modules/
    └── web_server/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Child Module (modules/web_server/outputs.tf)
```hcl
output "instance_ip_addr" {
  description = "Public IP address of the web server instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "Instance ID of the web server"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group ID for the web server"
  value       = aws_security_group.web.id
}
```

### Parent Module (main.tf)
```hcl
module "web_server" {
  source = "./modules/web_server"
  
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
}

# Access child module outputs
resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "A"
  ttl     = "300"
  records = [module.web_server.instance_ip_addr]
}
```

### Parent Module (outputs.tf)
```hcl
# Pass through child module outputs
output "web_server_ip" {
  description = "IP address of the web server"
  value       = module.web_server.instance_ip_addr
}

# Combine multiple child outputs
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    web_server_ip = module.web_server.instance_ip_addr
    web_server_id = module.web_server.instance_id
    environment   = var.environment
  }
}
```

### Important Considerations
- **Explicit Declaration:** Module outputs are not passed on from resources by default; they must be explicitly declared within the module's `outputs.tf` file
- **Access Pattern:** Always use the `module.<name>.<output>` syntax for accessing child module outputs
- **Dependency Chain:** Parent modules automatically depend on child module outputs being available

## Cross-Environment Data Flow

Cross-environment data flow creates a data pipeline between two completely separate Terraform environments, where the output of one environment becomes the input of another. This approach maintains environment isolation while allowing controlled information transfer.

### How It Works

1. **Source Environment:** Creates resources and exports outputs to its state file
2. **Target Environment:** Reads the source's state file using `terraform_remote_state`
3. **Data Flow:** Information flows from source outputs to target inputs during planning/apply

### Architecture Example

```
┌─────────────────┐    outputs     ┌─────────────────┐
│   Networking    │ ────────────> │   Application   │
│   Environment   │               │   Environment   │
│                 │               │                 │
│ ├─ VPC          │               │ ├─ EC2          │
│ ├─ Subnets      │               │ ├─ RDS          │
│ ├─ Route Tables │               │ ├─ Load Balancer│
│ └─ Security Grp │               │                 │
└─────────────────┘               └─────────────────┘
        │                                   │
        └─── State File ────────────────────┘
```

### Source Environment (Networking)

**main.tf:**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**outputs.tf:**
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
```

### Target Environment (Application)

**data.tf:**
```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-west-2"
  }
}
```

**main.tf:**
```hcl
resource "aws_instance" "web" {
  count                  = 2
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[count.index]
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.web_security_group_id]

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

resource "aws_lb" "web" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.networking.outputs.web_security_group_id]
  subnets            = data.terraform_remote_state.networking.outputs.public_subnet_ids
}
```

## Key Benefits of Cross-Environment Data Flow

### 1. Environment Isolation
- **Separate State Files:** Each environment maintains its own state
- **Independent Deployments:** Environments can be deployed and destroyed independently
- **Reduced Blast Radius:** Issues in one environment don't affect others
- **Team Autonomy:** Different teams can manage different environments

### 2. Controlled Dependencies
- **Explicit Data Contracts:** Clear definition of what data is shared through outputs
- **Type Safety:** Terraform validates data types across environments
- **Version Control:** Changes to shared data are tracked through version control
- **Dependency Visibility:** Clear visibility into inter-environment dependencies

### 3. Audit Trail
- **State Tracking:** State files track what data was transferred and when
- **Change History:** Complete history of infrastructure changes
- **Compliance:** Easier to meet compliance requirements with clear audit trails
- **Rollback Capability:** Ability to rollback to previous states

### 4. Operational Benefits
- **Environment Promotion:** Support for Dev → Staging → Prod workflows
- **Shared Configuration:** Central configuration consumed by multiple environments
- **Cross-Team Coordination:** Team A's outputs become Team B's inputs
- **Blue-Green Deployments:** New environments can reference existing environment data

## terraform_remote_state Data Source

The `terraform_remote_state` data source allows a Terraform configuration to access outputs from another Terraform configuration's state. This enables one project to read values from another, facilitating modular and multi-stage environments.

### Common Use Cases

**Scenario:** Multi-stage deployment where:
1. One Terraform project creates networking infrastructure (VPC, subnets, security groups)
2. Another project deploys applications and needs the networking information
3. Service project reads from the networking project outputs instead of duplicating logic

### Basic Syntax

```hcl
data "terraform_remote_state" "name" {
  backend = "backend_type"
  config = {
    # Backend-specific configuration
  }
}
```

### Backend Examples

#### S3 Backend
```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket"
    key    = "environments/production/networking.tfstate"
    region = "us-west-2"
  }
}
```

#### Azure Storage Backend
```hcl
data "terraform_remote_state" "core_infrastructure" {
  backend = "azurerm"
  config = {
    storage_account_name = "mystorageaccount"
    container_name       = "tfstate"
    key                 = "prod.terraform.tfstate"
  }
}
```

#### Google Cloud Storage Backend
```hcl
data "terraform_remote_state" "shared_services" {
  backend = "gcs"
  config = {
    bucket = "my-terraform-state"
    prefix = "shared-services"
  }
}
```

#### Terraform Cloud Backend
```hcl
data "terraform_remote_state" "platform" {
  backend = "remote"
  config = {
    organization = "my-org"
    workspaces = {
      name = "platform-infrastructure"
    }
  }
}
```

### Accessing Remote State Outputs

```hcl
# Access outputs from remote state
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.app_security_group_id]

  tags = {
    Name = "application-server"
    VPC  = data.terraform_remote_state.networking.outputs.vpc_id
  }
}

# Use in local values
locals {
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  
  common_tags = {
    Environment = "production"
    VPC         = local.vpc_id
    ManagedBy   = "terraform"
  }
}
```

## Alternative Approaches

### 1. Shared Backends
**Approach:** All environments use the same remote state with different keys/workspaces
**Pros:** Simpler setup, single backend configuration
**Cons:** Less isolation, potential for state conflicts, harder to manage permissions

### 2. External Stores
**Approach:** Use databases, S3 buckets, or other external systems for configuration sharing
**Pros:** More flexibility, can integrate with existing systems
**Cons:** More complexity, no type safety, additional infrastructure to manage

### 3. Configuration Files
**Approach:** Share data through JSON/YAML configuration files
**Pros:** Simple, human-readable, version-controlled
**Cons:** No type safety, manual synchronization, no automatic dependency tracking

### Comparison

| Approach | Isolation | Type Safety | Complexity | Automation |
|----------|-----------|-------------|------------|------------|
| Remote State | High | Yes | Medium | High |
| Shared Backend | Medium | Yes | Low | High |
| External Stores | High | No | High | Medium |
| Config Files | High | No | Low | Low |

## Best Practices

### 1. Output Design
- **Clear Naming:** Use descriptive names for outputs that clearly indicate their purpose
- **Comprehensive Documentation:** Always include descriptions for outputs
- **Consistent Structure:** Maintain consistent naming conventions across modules
- **Minimal Exposure:** Only expose outputs that are actually needed by consumers

### 2. Security Considerations
- **Sensitive Data:** Mark sensitive outputs appropriately and consider encryption at rest
- **Access Control:** Implement proper access controls on state files containing sensitive outputs
- **State File Security:** Ensure state files are encrypted and access is audited
- **Ephemeral Data:** Use ephemeral outputs for transient data that shouldn't be persisted

### 3. Module Organization
- **Dedicated Files:** Keep outputs in separate `outputs.tf` files for clarity
- **Logical Grouping:** Group related outputs together
- **Interface Design:** Design outputs as a stable interface for module consumers
- **Version Compatibility:** Consider backwards compatibility when changing outputs

### 4. Cross-Environment Management
- **Environment Naming:** Use consistent naming conventions for environments and state files
- **Dependency Mapping:** Document dependencies between environments clearly
- **State File Organization:** Organize state files logically by environment and component
- **Automated Testing:** Test cross-environment dependencies in CI/CD pipelines

### 5. Operational Excellence
- **State File Backup:** Regularly backup state files, especially those with important outputs
- **Monitoring:** Monitor for changes in critical outputs that other environments depend on
- **Documentation:** Maintain clear documentation of inter-environment dependencies
- **Gradual Migration:** When changing outputs, provide migration paths for dependent environments

## Common Patterns and Examples

### Environment Promotion Pattern
```hcl
# In staging environment
data "terraform_remote_state" "dev_app" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "dev/application.tfstate"
    region = "us-west-2"
  }
}

# Promote configuration from dev to staging
resource "aws_instance" "staging_app" {
  ami           = data.terraform_remote_state.dev_app.outputs.tested_ami_id
  instance_type = "t3.small"  # Larger than dev
  # ... other staging-specific configurations
}
```

### Shared Services Pattern
```hcl
# Multiple applications referencing shared services
data "terraform_remote_state" "shared_services" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "shared/services.tfstate"
    region = "us-west-2"
  }
}

resource "aws_instance" "app" {
  # Use shared VPC and security groups
  subnet_id              = data.terraform_remote_state.shared_services.outputs.app_subnet_id
  vpc_security_group_ids = [data.terraform_remote_state.shared_services.outputs.app_security_group_id]
  
  # Use shared database endpoint
  user_data = templatefile("app-config.tpl", {
    db_endpoint = data.terraform_remote_state.shared_services.outputs.database_endpoint
    cache_endpoint = data.terraform_remote_state.shared_services.outputs.redis_endpoint
  })
}
```

### Multi-Region Pattern
```hcl
# Application in us-east-1 referencing us-west-2 resources
data "terraform_remote_state" "west_coast" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "us-west-2/infrastructure.tfstate"
    region = "us-west-2"
  }
}

# Create cross-region resources
resource "aws_route53_record" "failover" {
  # Use outputs from both regions for failover configuration
  primary_ip   = aws_eip.primary.public_ip
  secondary_ip = data.terraform_remote_state.west_coast.outputs.backup_server_ip
}
```
