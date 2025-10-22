# Terraform Commands Cheat Sheet

Essential Terraform commands with descriptions and examples for Infrastructure as Code.

---

## Basic Workflow Commands

### `terraform init` - Initialize Working Directory
Initialize a Terraform working directory with provider plugins and backend.
```bash
terraform init                            # Initialize directory
terraform init -upgrade                   # Upgrade provider plugins
terraform init -reconfigure               # Reconfigure backend
terraform init -migrate-state             # Migrate state to new backend
terraform init -backend=false             # Skip backend initialization
terraform init -get=false                 # Skip module downloads
terraform init -input=false               # Disable interactive prompts
terraform init -plugin-dir=/path/to/plugins  # Use local plugins
terraform init -lockfile=readonly         # Don't update dependency lock file

# Initialize and copy state
terraform init -backend-config="bucket=my-bucket"  # Override backend config
terraform init -backend-config=backend.hcl         # Load from file
```

### `terraform plan` - Preview Changes
Generate and show execution plan.
```bash
terraform plan                            # Show plan
terraform plan -out=tfplan                # Save plan to file
terraform plan -destroy                   # Plan to destroy all resources
terraform plan -refresh=false             # Skip state refresh
terraform plan -target=resource.name      # Plan for specific resource
terraform plan -var="region=us-west-2"    # Pass variable
terraform plan -var-file="prod.tfvars"    # Use variables file
terraform plan -parallelism=10            # Control parallelism
terraform plan -detailed-exitcode         # Exit code 2 if changes

# Multiple targets
terraform plan -target=aws_instance.web -target=aws_security_group.sg

# Ignore remote state
terraform plan -lock=false                # Don't lock state
terraform plan -lock-timeout=30s          # Custom lock timeout

# Output plan in different formats
terraform plan -no-color                  # Disable colored output
terraform plan -compact-warnings          # Compact warning output
terraform plan -json                      # JSON output
```

### `terraform apply` - Apply Changes
Apply the changes required to reach desired state.
```bash
terraform apply                           # Apply with confirmation
terraform apply -auto-approve             # Apply without confirmation
terraform apply tfplan                    # Apply saved plan
terraform apply -target=resource.name     # Apply to specific resource
terraform apply -var="count=3"            # Pass variable
terraform apply -var-file="prod.tfvars"   # Use variables file
terraform apply -parallelism=10           # Control parallelism
terraform apply -refresh=false            # Skip state refresh
terraform apply -replace=aws_instance.web # Force replacement
terraform apply -lock=false               # Don't lock state
terraform apply -lock-timeout=30s         # Custom lock timeout
terraform apply -compact-warnings         # Compact warnings
terraform apply -json                     # JSON output

# Multiple targets
terraform apply -target=module.vpc -target=aws_instance.web

# Input from plan file
terraform apply "tfplan"
```

### `terraform destroy` - Destroy Infrastructure
Destroy all managed infrastructure.
```bash
terraform destroy                         # Destroy with confirmation
terraform destroy -auto-approve           # Destroy without confirmation
terraform destroy -target=resource.name   # Destroy specific resource
terraform destroy -var="region=us-west-2" # Pass variable
terraform destroy -var-file="prod.tfvars" # Use variables file
terraform destroy -parallelism=10         # Control parallelism
terraform destroy -refresh=false          # Skip state refresh

# Destroy specific resources
terraform destroy -target=aws_instance.web
terraform destroy -target=module.database

# Plan destroy first
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

---

## State Management

### `terraform state` - Advanced State Management
Manage Terraform state.
```bash
# List resources in state
terraform state list                      # List all resources
terraform state list aws_instance         # Filter by type
terraform state list module.vpc           # List module resources

# Show resource details
terraform state show resource.name        # Show resource details
terraform state show 'aws_instance.web[0]' # Show indexed resource

# Move resources
terraform state mv source dest            # Rename resource
terraform state mv aws_instance.old aws_instance.new
terraform state mv module.old module.new
terraform state mv 'aws_instance.web[0]' 'aws_instance.web[1]'

# Remove resources from state
terraform state rm resource.name          # Remove from state (doesn't destroy)
terraform state rm 'aws_instance.web[*]'  # Remove all instances
terraform state rm module.vpc             # Remove entire module

# Pull/Push state
terraform state pull                      # Download remote state
terraform state pull > state.tfstate      # Save to file
terraform state push state.tfstate        # Upload state file

# Replace provider
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

### `terraform refresh` - Refresh State
Update state file with real infrastructure.
```bash
terraform refresh                         # Refresh state
terraform refresh -var="region=us-west-2" # With variables
terraform refresh -var-file="prod.tfvars" # With variable file
terraform refresh -target=resource.name   # Refresh specific resource
terraform refresh -lock=false             # Don't lock state

# Note: terraform refresh is deprecated, use:
terraform apply -refresh-only             # Recommended alternative
terraform plan -refresh-only              # Preview refresh changes
```

---

## Output and Variables

### `terraform output` - Read Output Values
Display output values from state.
```bash
terraform output                          # Show all outputs
terraform output name                     # Show specific output
terraform output -json                    # JSON format
terraform output -raw name                # Raw output (no quotes)

# Use in scripts
PUBLIC_IP=$(terraform output -raw public_ip)
terraform output -json | jq '.vpc_id.value'
```

### `terraform console` - Interactive Console
Interactive console for evaluating expressions.
```bash
terraform console                         # Start console
terraform console -var="region=us-east-1" # With variables
terraform console -var-file="prod.tfvars" # With variable file

# Example expressions in console:
# > var.region
# > local.common_tags
# > aws_instance.web.public_ip
# > length(var.availability_zones)
# > [for s in var.subnets : s.cidr]
```

---

## Formatting and Validation

### `terraform fmt` - Format Configuration Files
Format Terraform configuration files.
```bash
terraform fmt                             # Format current directory
terraform fmt -recursive                  # Format subdirectories
terraform fmt -diff                       # Show formatting changes
terraform fmt -check                      # Check if formatted (CI/CD)
terraform fmt -write=false                # Don't write changes
terraform fmt file.tf                     # Format specific file

# Use in CI/CD
terraform fmt -check -recursive           # Fail if not formatted
```

### `terraform validate` - Validate Configuration
Validate configuration syntax.
```bash
terraform validate                        # Validate configuration
terraform validate -json                  # JSON output
terraform validate -no-color              # Disable colors

# Typical workflow
terraform init
terraform validate
terraform plan
```

---

## Workspaces

### `terraform workspace` - Manage Workspaces
Manage multiple environments with workspaces.
```bash
# List workspaces
terraform workspace list                  # Show all workspaces
terraform workspace show                  # Show current workspace

# Create workspace
terraform workspace new dev               # Create new workspace
terraform workspace new -state=dev.tfstate dev  # With existing state

# Switch workspace
terraform workspace select dev            # Switch to workspace
terraform workspace select default        # Switch to default

# Delete workspace
terraform workspace delete dev            # Delete workspace

# Use in configuration
# var.workspace = terraform.workspace
```

---

## Import and Providers

### `terraform import` - Import Existing Resources
Import existing infrastructure into Terraform state.
```bash
# Basic import
terraform import resource.name id         # Import resource

# Examples by resource type
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_s3_bucket.bucket my-bucket-name
terraform import aws_security_group.sg sg-1234567890abcdef0
terraform import aws_vpc.main vpc-1234567890abcdef0
terraform import module.vpc.aws_vpc.main vpc-1234567890abcdef0

# With variables
terraform import -var="region=us-west-2" resource.name id
terraform import -var-file="prod.tfvars" resource.name id

# Note: You must write the configuration block first
# Example:
# resource "aws_instance" "web" {
#   # ... configuration
# }
# terraform import aws_instance.web i-1234567890abcdef0
```

### `terraform providers` - Show Providers
Show provider requirements and versions.
```bash
terraform providers                       # List providers
terraform providers schema -json          # Provider schemas in JSON
terraform providers mirror /path          # Mirror providers to directory
terraform providers lock                  # Update dependency lock file

# View provider documentation
terraform providers schema -json | jq '.provider_schemas'
```

---

## Module Management

### `terraform get` - Download Modules
Download and update modules.
```bash
terraform get                             # Download modules
terraform get -update                     # Update modules
terraform get -no-color                   # Disable colors

# Note: Usually done automatically with terraform init
```

### Module Commands
Working with modules.
```bash
# Initialize with modules
terraform init                            # Download modules

# Update modules
terraform init -upgrade                   # Upgrade modules

# List modules
terraform state list | grep module        # List module resources

# Target module in commands
terraform plan -target=module.vpc
terraform apply -target=module.database
terraform destroy -target=module.network
```

---

## Graph and Visualization

### `terraform graph` - Generate Dependency Graph
Generate visual dependency graph.
```bash
terraform graph                           # Generate DOT format
terraform graph | dot -Tpng > graph.png   # Generate PNG image
terraform graph | dot -Tsvg > graph.svg   # Generate SVG image
terraform graph -type=plan                # Plan-time graph
terraform graph -type=apply               # Apply-time graph
terraform graph -draw-cycles              # Highlight cycles

# View in browser (requires graphviz)
terraform graph | dot -Tsvg > graph.svg && open graph.svg
```

---

## Version Management

### `terraform version` - Show Version
Display Terraform version.
```bash
terraform version                         # Show version
terraform version -json                   # JSON format
terraform -version                        # Alternative syntax
terraform -v                              # Short version
```

---

## Remote Operations

### `terraform login` / `terraform logout` - Terraform Cloud Authentication
Authenticate with Terraform Cloud.
```bash
terraform login                           # Login to Terraform Cloud
terraform login app.terraform.io          # Login to specific hostname
terraform logout                          # Logout
terraform logout app.terraform.io         # Logout from specific hostname
```

### `terraform force-unlock` - Unlock State
Manually unlock state if locked.
```bash
terraform force-unlock LOCK_ID            # Unlock state
terraform force-unlock -force LOCK_ID     # Force unlock without confirmation

# Get lock ID from error message
# Example: Error: Error acquiring the state lock
#          Lock Info:
#            ID:        1234abcd-5678-efgh-9012-ijklmnop3456
```

---

## Testing and Debugging

### `terraform show` - Show State or Plan
Show current state or saved plan.
```bash
terraform show                            # Show current state
terraform show tfplan                     # Show saved plan
terraform show -json                      # JSON output
terraform show -json tfplan               # Plan in JSON
terraform show -no-color                  # Disable colors

# Parse with jq
terraform show -json | jq '.values.root_module.resources'
terraform show -json tfplan | jq '.resource_changes'
```

### Debugging
Enable debug logging.
```bash
# Enable debug logs
export TF_LOG=TRACE                       # Most verbose (TRACE, DEBUG, INFO, WARN, ERROR)
export TF_LOG=DEBUG
export TF_LOG=INFO

# Log to file
export TF_LOG_PATH=terraform.log
terraform plan

# Disable logging
unset TF_LOG
unset TF_LOG_PATH

# Debug specific subsystems
export TF_LOG_CORE=TRACE                  # Core Terraform
export TF_LOG_PROVIDER=TRACE              # Provider operations
```

### `terraform test` - Run Tests
Run Terraform tests (Terraform 1.6+).
```bash
terraform test                            # Run all tests
terraform test -verbose                   # Verbose output
terraform test -filter=tests/test1.tftest.hcl  # Run specific test
terraform test -json                      # JSON output
```

---

## Advanced Commands

### `terraform taint` / `terraform untaint` - Mark for Replacement (deprecated)
Mark resource for recreation (use -replace instead).
```bash
# Deprecated - use terraform apply -replace instead
terraform taint resource.name             # Mark for recreation
terraform untaint resource.name           # Remove taint

# Modern approach
terraform apply -replace=aws_instance.web
terraform plan -replace=aws_instance.web
```

### `terraform metadata` - Show Metadata
Show metadata about configuration.
```bash
terraform metadata functions              # List available functions
terraform metadata functions -json        # JSON format
```

---

## Configuration Block Examples

### Backend Configuration
Configure remote state backend.
```hcl
# S3 Backend
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

# Terraform Cloud
terraform {
  backend "remote" {
    organization = "my-org"
    workspaces {
      name = "production"
    }
  }
}

# Local Backend
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### Provider Configuration
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
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

---

## Common Workflows

### Initial Setup
```bash
# 1. Create configuration files
mkdir terraform-project
cd terraform-project
touch main.tf variables.tf outputs.tf

# 2. Initialize
terraform init

# 3. Validate
terraform validate

# 4. Format
terraform fmt -recursive

# 5. Plan
terraform plan -out=tfplan

# 6. Apply
terraform apply tfplan
```

### Making Changes
```bash
# 1. Edit configuration files
vim main.tf

# 2. Format
terraform fmt

# 3. Validate
terraform validate

# 4. Plan
terraform plan

# 5. Apply
terraform apply -auto-approve
```

### Importing Existing Infrastructure
```bash
# 1. Write resource block
cat >> main.tf << 'EOF'
resource "aws_instance" "imported" {
  # Configuration will be filled after import
}
EOF

# 2. Import resource
terraform import aws_instance.imported i-1234567890abcdef0

# 3. View imported state
terraform state show aws_instance.imported

# 4. Update configuration to match
vim main.tf

# 5. Verify no changes needed
terraform plan
```

### Migrating State Backend
```bash
# 1. Update backend configuration in main.tf
# 2. Initialize with migration
terraform init -migrate-state

# 3. Verify state
terraform state list

# 4. Test with plan
terraform plan
```

### Destroying Resources
```bash
# 1. Review what will be destroyed
terraform plan -destroy

# 2. Destroy specific resource
terraform destroy -target=aws_instance.test

# 3. Destroy everything
terraform destroy -auto-approve
```

---

## State File Management

### Backup State
```bash
# Pull and backup current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# List backups
ls -lh backup-*.tfstate
```

### Restore State
```bash
# Push backed up state
terraform state push backup-20240115-120000.tfstate

# Note: Use with caution, verify backup first
```

### Move Resources Between States
```bash
# Export from source
cd source-project
terraform state pull > exported.tfstate

# Import to destination
cd destination-project
terraform state push exported.tfstate

# Or use state mv
terraform state mv -state=source.tfstate -state-out=dest.tfstate resource.name resource.new_name
```

---

## CI/CD Integration

### Terraform in CI/CD Pipeline
```bash
# Validate
terraform init -backend=false
terraform validate
terraform fmt -check -recursive

# Plan
terraform init
terraform plan -out=tfplan

# Apply
terraform apply -auto-approve tfplan

# Output
terraform output -json > outputs.json

# Destroy (if needed)
terraform destroy -auto-approve
```

### Using terraform plan exit codes
```bash
# Exit codes:
# 0 = Success with empty diff (no changes)
# 1 = Error
# 2 = Success with non-empty diff (changes present)

terraform plan -detailed-exitcode
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "No changes needed"
elif [ $EXIT_CODE -eq 1 ]; then
  echo "Plan failed"
  exit 1
elif [ $EXIT_CODE -eq 2 ]; then
  echo "Changes detected"
  # Proceed with apply
fi
```

---

## Environment Variables

### Configuration
```bash
# Credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Terraform variables (alternative to -var)
export TF_VAR_region="us-west-2"
export TF_VAR_instance_type="t2.micro"
export TF_VAR_environment="production"

# Workspace
export TF_WORKSPACE="development"

# Input
export TF_INPUT=false                     # Disable interactive prompts

# CLI configuration
export TF_CLI_ARGS="-no-color"
export TF_CLI_ARGS_plan="-parallelism=10"
export TF_CLI_ARGS_apply="-auto-approve"

# Data directory
export TF_DATA_DIR=".terraform"

# Plugin cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
```

---

## Best Practices Commands

### Pre-commit Checks
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan (with tfsec)
tfsec .

# Linting (with tflint)
tflint
```

### Safe Apply Workflow
```bash
# 1. Always plan first
terraform plan -out=tfplan

# 2. Review the plan
terraform show tfplan

# 3. Apply the saved plan
terraform apply tfplan

# 4. Verify outputs
terraform output
```

### State Locking
```bash
# Default behavior (with locking)
terraform apply

# Override (use carefully)
terraform apply -lock=false

# Custom lock timeout
terraform apply -lock-timeout=5m
```

---

## Troubleshooting Commands

### Fix Common Issues
```bash
# Corrupted state
terraform state pull > state.backup
# Edit state.backup if needed
terraform state push state.backup

# Stuck in locking
terraform force-unlock LOCK_ID

# Provider issues
rm -rf .terraform
terraform init -upgrade

# Module issues
rm -rf .terraform/modules
terraform get -update
terraform init

# Dependency lock issues
terraform providers lock \
  -platform=darwin_amd64 \
  -platform=linux_amd64 \
  -platform=windows_amd64
```

### Verify Installation
```bash
# Check version
terraform version

# Verify providers
terraform providers

# Check configuration
terraform validate

# List workspace
terraform workspace list
```

---

## Useful Aliases

Add to `.bashrc` or `.zshrc`:
```bash
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'
alias tfs='terraform state'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
alias tfw='terraform workspace'
alias tfaa='terraform apply -auto-approve'
alias tfda='terraform destroy -auto-approve'
```

---

## Quick Reference

### Essential Command Sequence
```bash
terraform init                # Initialize
terraform validate            # Validate syntax
terraform fmt                 # Format code
terraform plan                # Preview changes
terraform apply               # Apply changes
terraform output              # View outputs
terraform destroy             # Destroy resources
```

### State Operations
```bash
terraform state list          # List resources
terraform state show resource # Show details
terraform state mv old new    # Rename
terraform state rm resource   # Remove from state
terraform state pull          # Download state
```

### Common Flags
```bash
-auto-approve                 # Skip confirmation
-var="key=value"              # Pass variable
-var-file="vars.tfvars"       # Variable file
-target=resource              # Target specific resource
-out=file                     # Save plan
-json                         # JSON output
-no-color                     # Disable colors
```
