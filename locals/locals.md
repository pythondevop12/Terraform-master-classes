# Terraform Locals — Complete Notes

---

## What are Locals?

Locals are **named expressions** defined once and reused anywhere in your configuration.

They are not variables — they cannot be passed in from outside.
They are not outputs — they are never exposed.
They are purely **internal shortcuts** that live inside your config.

> **One-liner:** Locals = write once, use everywhere, change in one place.

---

## Why Locals Exist

Without locals, you end up repeating the same expression in 10 different places.
When that expression needs to change, you update 10 places — and miss one.

Locals solve this by letting you define the expression **once** and reference it **everywhere.**

---

## Syntax

```hcl
locals {
  <name> = <expression>
}
```

Reference it anywhere with:

```hcl
local.<name>
```

You can have multiple `locals` blocks in the same file or across files — Terraform merges them all.

---

## Simple Examples

```hcl
locals {
  env         = "production"
  app_name    = "payments-service"
  owner       = "platform-team"
  region      = "us-east-1"
}
```

Use them:

```hcl
resource "aws_s3_bucket" "app" {
  bucket = "${local.app_name}-${local.env}-bucket"

  tags = {
    Environment = local.env
    Owner       = local.owner
  }
}
```

---

## Locals vs Variables — Key Difference

| | `variable` | `local` |
|---|---|---|
| Set from outside | Yes (tfvars, CLI, env) |  No |
| Set inside config |  No |  Yes |
| Can use expressions |  No |  Yes |
| Exposed to caller |  Yes |  Never |
| Use for | User input | Internal logic |

**Rule of thumb:**
- If the value comes **from outside** → `variable`
- If the value is **computed inside** → `local`

---

## Locals with Expressions

This is where locals get powerful. You can use any Terraform expression inside a local.

### String interpolation
```hcl
locals {
  bucket_name = "${var.app_name}-${var.env}-${var.region}"
}
```

### Conditionals
```hcl
locals {
  is_prod        = var.env == "production"
  instance_type  = local.is_prod ? "t3.large" : "t3.micro"
}
```

### Arithmetic
```hcl
locals {
  total_capacity = var.min_nodes + var.max_nodes
}
```

### String functions
```hcl
locals {
  name_upper = upper(var.app_name)
  name_slug  = replace(lower(var.app_name), " ", "-")
}
```

---

## Locals for Tags — Most Common Real-World Use

Instead of repeating the same tags on every resource:

```hcl
# Without locals — repeated on every resource (bad)
resource "aws_instance" "web" {
  tags = {
    Environment = "production"
    Team        = "platform"
    ManagedBy   = "Terraform"
    Project     = "payments"
  }
}

resource "aws_s3_bucket" "app" {
  tags = {
    Environment = "production"   # copy-paste
    Team        = "platform"     # copy-paste
    ManagedBy   = "Terraform"    # copy-paste
    Project     = "payments"     # copy-paste
  }
}
```

```hcl
# With locals — defined once, used everywhere (good)
locals {
  common_tags = {
    Environment = var.env
    Team        = "platform"
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}

resource "aws_s3_bucket" "app" {
  tags = local.common_tags
}
```

Now if you need to add a new tag, you change **one place.**

---

## Locals with merge() — Extending Common Tags

When a resource needs all common tags PLUS its own specific tags:

```hcl
locals {
  common_tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "web" {
  tags = merge(local.common_tags, {
    Name = "web-server"
    Role = "frontend"
  })
}

resource "aws_instance" "db" {
  tags = merge(local.common_tags, {
    Name = "db-server"
    Role = "database"
  })
}
```

`merge()` combines both maps. Common tags apply to all, specific tags per resource.

---

## Locals Before Loops (for_each / count)

This is where locals become essential.

When using `for_each`, you often need to **transform or filter** your input data before passing it to a resource. Doing this transformation inline inside `for_each` makes code unreadable.

Locals let you **prepare the data first**, then pass the clean result to `for_each`.

### Example — filter a list before looping

```hcl
variable "users" {
  default = [
    { name = "alice", role = "admin",  active = true  },
    { name = "bob",   role = "viewer", active = false },
    { name = "carol", role = "admin",  active = true  },
  ]
}

locals {
  # Step 1 — filter: only active users
  active_users = [
    for u in var.users : u
    if u.active == true
  ]

  # Step 2 — transform: convert list to map keyed by name
  # for_each requires a map or set, not a list
  active_users_map = {
    for u in local.active_users : u.name => u
  }
}

resource "aws_iam_user" "this" {
  for_each = local.active_users_map

  name = each.key
  tags = {
    Role = each.value.role
  }
}
```

**What happened:**
1. `active_users` filtered out inactive users
2. `active_users_map` converted the list to a map (required by `for_each`)
3. The resource block stays clean — no logic inside it

---

## Locals with for Expressions — Transform Data

```hcl
variable "instance_names" {
  default = ["web", "api", "worker"]
}

locals {
  # Create a map of name → instance type
  instance_map = {
    for name in var.instance_names :
    name => "t3.micro"
  }

  # Create uppercased name list
  names_upper = [for name in var.instance_names : upper(name)]

  # Create a map with computed values
  bucket_names = {
    for name in var.instance_names :
    name => "${var.env}-${name}-bucket"
  }
}
```

---

## Locals Referencing Other Locals

Locals can reference each other — Terraform resolves the dependency order automatically.

```hcl
locals {
  env      = var.environment
  app      = var.app_name
  prefix   = "${local.env}-${local.app}"          # uses env and app
  bucket   = "${local.prefix}-data"               # uses prefix
  log_bucket = "${local.prefix}-logs"             # uses prefix
  full_name  = "${local.bucket}-${local.env}"     # uses bucket and env
}
```

Terraform figures out the order. You don't need to worry about sequence.

>  **Circular references are not allowed.** If local A references local B and local B references local A → Terraform errors.

---

## Locals with Conditionals — Environment-based Config

```hcl
locals {
  is_prod = var.env == "production"

  # Pick instance size based on environment
  instance_type = local.is_prod ? "t3.large" : "t3.micro"

  # Enable deletion protection only in prod
  deletion_protection = local.is_prod ? true : false

  # Set replica count based on environment
  replica_count = local.is_prod ? 3 : 1

  # Different S3 bucket name per env
  bucket_name = local.is_prod ? "prod-app-data" : "${var.env}-app-data"
}
```

One variable (`var.env`) drives multiple decisions through locals. Clean and centralized.

---

## Locals with toset() — Preparing for for_each

`for_each` on a list requires converting it to a **set** first.
Locals are the right place to do this conversion.

```hcl
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  az_set = toset(var.availability_zones)
}

resource "aws_subnet" "this" {
  for_each          = local.az_set
  availability_zone = each.key
  cidr_block        = "10.0.${index(var.availability_zones, each.key)}.0/24"
  vpc_id            = aws_vpc.main.id
}
```

---

## What Locals Cannot Do

| Limitation | Why |
|---|---|
| Cannot accept external input | They are not variables |
| Cannot be overridden at runtime | Fixed at config evaluation time |
| Cannot reference resources | Only variables, data sources, and other locals |
| Cannot be circular | A → B → A causes an error |
| Not visible in `terraform output` | Internal only |

---

## Common Patterns Summary

| Pattern | What it does |
|---|---|
| `common_tags` local | Define tags once, apply everywhere |
| `merge(local.common_tags, {...})` | Extend common tags per resource |
| `for u in var.list : u if u.active` | Filter a list before looping |
| `for u in var.list : u.name => u` | Convert list to map for for_each |
| `toset(var.list)` in a local | Prepare a set for for_each |
| `var.env == "prod" ? x : y` | Conditional config per environment |
| Locals referencing locals | Build values in steps, keep each local simple |

---

## Key Rules to Remember

**1.** Use `local.` (singular) to reference — never `locals.`

**2.** Multiple `locals {}` blocks are fine — Terraform merges them

**3.** Locals are evaluated at plan time — not runtime

**4.** No circular dependencies — Terraform will catch it and error

**5.** Locals are scoped to the module — not visible outside

---

## One-liner Summary

> Locals simplify your config by letting you name and reuse complex expressions — especially critical before loops, for common tags, and for environment-based logic.
