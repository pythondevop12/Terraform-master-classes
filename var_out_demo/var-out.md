# Terraform Variables & Outputs
> **PythonDevOps Series** | Prev: (S3 bucket, hardcoded values)

---

## Project Structure

```
terraform-video4/
├── main.tf           # Resources
├── variables.tf      # Variable declarations
├── outputs.tf        # Output declarations
└── terraform.tfvars  # Actual values
```

---

## Problem — Why Hardcoding is Bad

```hcl
# main.tf (Video 3) 
resource "aws_s3_bucket" "demo" {
  bucket = "pythondevops-video3-demo"   # hardcoded
  tags = {
    Env = "dev"                       # hardcoded
  }
}
```

- Can't reuse same code for dev / staging / prod
- Risk of committing secrets to Git
- Changing values means editing core logic file

---

## 1. variables.tf

> Think of it like **function parameters** in Python — declare what inputs your config accepts.

### Syntax

```hcl
variable "variable_name" {
  description = "What this variable does"
  type        = string        # string | number | bool | list | map | any
  default     = "some-value"  # optional — omit to make it REQUIRED
}
```

### Full File

```hcl
# variables.tf

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  # No default — MUST be provided
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "pythondevops"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
}
```

### Variable Types

| Type | Example | Use Case |
|------|---------|----------|
| `string` | `"us-east-1"` | Region, name, environment |
| `number` | `3` | Instance count, port |
| `bool` | `true` / `false` | Feature flags, enable/disable |
| `list(string)` | `["dev", "prod"]` | AZs, CIDR blocks |
| `map(string)` | `{ Env = "dev" }` | Tags, config maps |
| `any` | anything | Flexible — avoid if possible |

---

## 2. terraform.tfvars

> Where you **set actual values**. Terraform auto-loads this file on every `plan` / `apply`.

```hcl
# terraform.tfvars

aws_region        = "us-east-1"
bucket_name       = "pythondevops-video4-demo"
environment       = "dev"
project_name      = "pythondevops"
enable_versioning = true
```

> ⚠️ Add `terraform.tfvars` to `.gitignore` if it contains secrets.

### Multiple Environments

```bash
# Separate file per environment
dev.tfvars
staging.tfvars
prod.tfvars

# Apply with a specific file
terraform apply -var-file="prod.tfvars"
```

---

## 3. main.tf (Updated)

```hcl
# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region       #  variable
}

resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name      #  variable

  tags = {
    Env       = var.environment   #  variable
    Project   = var.project_name  #  variable
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}
```

---

## 4. outputs.tf

> Think of it like a **return value** in Python — Terraform prints these after `apply`. Also used by other modules to reference your resources.

### Syntax

```hcl
output "output_name" {
  description = "What this output shows"
  value       = resource_type.resource_name.attribute
  sensitive   = false   # set true to hide secrets from terminal
}
```

### Full File

```hcl
# outputs.tf

output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "The region where the bucket was created"
  value       = aws_s3_bucket.demo.region
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.demo.bucket_domain_name
}

output "versioning_status" {
  description = "Current versioning status of the bucket"
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}
```

### What You See After `terraform apply`

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn         = "arn:aws:s3:::pythondevops-video4-demo"
bucket_domain_name = "pythondevops-video4-demo.s3.amazonaws.com"
bucket_name        = "pythondevops-video4-demo"
bucket_region      = "us-east-1"
versioning_status  = "Enabled"
```

---

## Variable Priority Order (High → Low)

| Priority | Method | Example |
|----------|--------|---------|
| 1 — Highest | `-var` flag | `terraform apply -var="bucket_name=my-bucket"` |
| 2 | `-var-file` flag | `terraform apply -var-file="prod.tfvars"` |
| 3 | `terraform.tfvars` | Auto-loaded file |
| 4 | `TF_VAR_` env var | `export TF_VAR_bucket_name=my-bucket` |
| 5 — Lowest | `default` in variable block | `default = "fallback"` |

---

## CLI Commands

```bash
# Initialize
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# See all outputs
terraform output

# See a specific output
terraform output bucket_arn

# Destroy
terraform destroy
```

---

## Key Concepts Summary

| File | Role | Python Equivalent |
|------|------|-------------------|
| `variables.tf` | Declares variables | Function signature / parameters |
| `terraform.tfvars` | Sets variable values | Function arguments |
| `outputs.tf` | Exposes resource info | Return values |
| `var.name` | References a variable | Using a parameter inside a function |

---

## Best Practices

- Always add `description` to every variable and output
- Use `sensitive = true` on outputs with secrets
- Never hardcode region, names, or env values in `main.tf`
- Gitignore `terraform.tfvars` if it contains secrets
- No `default` if a variable should always be explicitly set

---


---

*PythonDevOps — Video 4*
