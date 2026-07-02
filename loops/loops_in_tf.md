# Terraform Loops —  Notes

> **Topic:** Terraform Loops | **Channel:** PythonDevOpsAcademy
> **Covers:** `count` · `for_each` · `for` expressions
> **AWS Region:** us-east-1 | **Terraform:** 1.10+

---

## Slide 1 — Introduction

Terraform loops let you create multiple infrastructure resources from a single resource block. Instead of copy-pasting resource definitions, you write one block and let Terraform repeat it.

**Three loop tools covered in this episode:**

| Tool | Purpose |
|------|---------|
| `count` | Create N identical copies of a resource |
| `for_each` | Create N named copies, each with a unique key |
| `for` | Transform data collections — does NOT create resources |

---

## Slide 2 — The Problem: Copy-Paste Infrastructure

### Scenario

You need one S3 bucket per environment — dev, stage, prod.

**Without loops:**

```hcl
resource "aws_s3_bucket" "dev" {
  bucket = "myapp-dev"
}
resource "aws_s3_bucket" "stage" {
  bucket = "myapp-stage"
}
resource "aws_s3_bucket" "prod" {
  bucket = "myapp-prod"
}
```

### Problems with this approach

- ✗ Three blocks doing the same thing
- ✗ Add a 4th env → write another block manually
- ✗ Config change → edit all 3 blocks
- ✗ Easy to miss one → configuration drift risk
- ✗ Violates the **DRY** principle (Don't Repeat Yourself)

> The bigger your infrastructure, the worse this gets. Loops are the fix.

---

## Slide 3 — The Solution: Loop Once, Deploy Many

The same 3 S3 buckets rewritten with `for_each`:

```hcl
variable "environments" {
  default = ["dev", "stage", "prod"]
}

resource "aws_s3_bucket" "app" {
  for_each = toset(var.environments)
  bucket   = "myapp-${each.key}"
}
```

**One block handles all three buckets.**

### Benefits

- ✓ 1 resource block handles all envs
- ✓ Add env → edit the list only
- ✓ Config change → 1 place to edit
- ✓ Scales to any number of items
- ✓ Readable & maintainable

### Adding a 4th environment

```hcl
# Just add "dr" to the list — Terraform does the rest
default = ["dev", "stage", "prod", "dr"]
```

---

## Slide 4 — Three Ways to Loop in Terraform

### `count` — Index-based repetition

Set `count = N` to create N copies of a resource. Each instance is identified by a numeric index — `count.index` — starting at 0.

**Use when:** Identical or near-identical resources where order doesn't matter.

---

### `for_each` — Key-based repetition

Iterate over a map or a set. Each resource instance has a unique string key — `each.key` — and an optional value — `each.value`.

**Use when:** Resources that differ by name, tag, or configuration.

---

### `for` — Collection transformation

Transform a list or map into a new list or map inside an expression. **Does NOT create resources.** Used in locals, variable defaults, and outputs.

**Use when:** Building or reshaping values, not creating infrastructure.

> **Key distinction:** `count` and `for_each` are meta-arguments on resource blocks that create infrastructure. `for` is an expression that transforms data.

---

## Slide 5 — `count`: How It Works

### Syntax

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0abcdef"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server-${count.index}"
  }
}
```

### What Terraform creates in state

| Resource address | Name tag |
|---|---|
| `aws_instance.web[0]` | `"web-server-0"` |
| `aws_instance.web[1]` | `"web-server-1"` |
| `aws_instance.web[2]` | `"web-server-2"` |

### Key facts

- `count.index` starts at **0** and increments by 1 for each instance
- Resources are addressed using **square bracket + numeric index**: `resource[0]`, `resource[1]`
- `count = 0` effectively **disables** a resource (creates nothing)

### Referencing a count resource from outside

```hcl
output "ip" {
  value = aws_instance.web[0].public_ip
}
```

---

## Slide 6 — `count`: The Index Shift Gotcha

This is the most important limitation of `count`.

### What happens when you remove a middle item?

**Before (count = 3):**

```
[0] → web-server-0  (dev)
[1] → web-server-1  (stage)  ← delete this
[2] → web-server-2  (prod)
```

**After removing "stage" (count = 2):**

```
[0] → web-server-0  (dev)
[1] → web-server-1  (prod)   ← SHIFTED! was index 2
```

### What Terraform sees in the plan

```
destroy  aws_instance.web[2]   # prod server gets destroyed!
update   aws_instance.web[1]   # was stage, now points to prod
```

> Your **prod server gets destroyed** because you removed staging from the middle of the list. Terraform tracks count resources by position, not by name.

### Rule

Use `count` only when:
- All instances are **truly identical**
- You **rarely remove** items from the middle of the list

If resources have meaningful names (dev, stage, prod), use `for_each` — it doesn't have this problem.

---

## Slide 7 — `for_each`: How It Works

`for_each` accepts two types of input.

### ① Map input — items have different configs

```hcl
variable "instances" {
  default = {
    dev  = "t2.micro"
    prod = "t3.small"
  }
}

resource "aws_instance" "app" {
  for_each      = var.instances
  instance_type = each.value   # t2.micro or t3.small
  tags = { Name = each.key }   # "dev" or "prod"
}
```

### ② Set input — items only have names (use `toset()`)

```hcl
resource "aws_s3_bucket" "app" {
  for_each = toset(["dev", "stage", "prod"])
  bucket   = "myapp-${each.key}"
}
```

> ⚠️ `for_each` cannot accept a plain list `[ ]`. You must wrap it in `toset()` first.

### The loop variables

| Variable | What it contains |
|---|---|
| `each.key` | The map key, or the set element. Always a string. |
| `each.value` | The map value. For sets: same as `each.key`. |

### Referencing a for_each resource from outside

```hcl
aws_s3_bucket.app["dev"].arn
aws_instance.app["prod"].public_ip
```

Resources are addressed using **square bracket + string key**: `resource["key"]`.

---

## Slide 8 — `for_each`: No Index Shift Problem

`for_each` is safe to modify. Let's replay the same "remove stage" scenario.

**Before:**

```
["dev"]   → myapp-dev
["stage"] → myapp-stage   ← remove this
["prod"]  → myapp-prod
```

**After removing "stage":**

```
["dev"]   → myapp-dev    ✓ untouched
["prod"]  → myapp-prod   ✓ untouched
```

### Terraform plan

```
destroy  aws_s3_bucket.app["stage"]   # only stage — nothing else touched ✓
```

### Why?

Each resource is tracked by its **string key**, not a numeric position. Removing `"stage"` only affects the `"stage"` resource. Dev and prod don't even know stage was removed.

> This is why `for_each` is the preferred choice for any named infrastructure in production.

---

## Slide 9 — `for` Expression: Data Transformation

> ⚠️ **Important:** `for` expression does **NOT** create resources — it transforms data.

### Syntax

```hcl
# Produces a list (square brackets)
[ for <item> in <list> : <expression> ]

# Produces a map (curly braces)
{ for <item> in <list> : <key> => <value> }
```

### Examples

**List → List (transform each element)**

```hcl
[ for env in var.envs : upper(env) ]
# Input:  ["dev", "stage", "prod"]
# Output: ["DEV", "STAGE", "PROD"]
```

**List → Map (build a lookup table)**

```hcl
{ for env in var.envs : env => "${env}-bucket" }
# Output: { dev = "dev-bucket", stage = "stage-bucket", prod = "prod-bucket" }
```

**With `if` filter (exclude items)**

```hcl
[ for e in var.envs : e if e != "dev" ]
# Output: ["stage", "prod"]  — dev excluded
```

### Rules

| Bracket type | Output type |
|---|---|
| `[ ]` | Produces a **list** (tuple) |
| `{ }` | Produces a **map** — must use `key => value` syntax |

Optional `if` clause filters elements before the expression runs.

---

## Slide 10 — `for` Expression: Practical Uses

### In `locals` — derive a list from a variable

```hcl
locals {
  bucket_names = [ for e in var.envs : "${var.app}-${e}" ]
  # Result: ["myapp-dev", "myapp-stage", "myapp-prod"]
}
```

### In `outputs` — extract a field from every resource

```hcl
output "all_bucket_arns" {
  value = { for k, v in aws_s3_bucket.app : k => v.arn }
  # Result: { dev = "arn:...", stage = "arn:...", prod = "arn:..." }
}
```

### In `for_each` — filter a list before creating resources

```hcl
resource "aws_s3_bucket" "app" {
  for_each = toset([ for e in var.envs : e if e != "test" ])
  bucket   = "myapp-${each.key}"
}
```

> **Key reminder:** `for` = data transformation only. `count` / `for_each` = resource creation.

---

## Slide 11 — `count` vs `for_each`: Side by Side

| | `count` | `for_each` |
|---|---|---|
| **Input type** | A number (e.g. `count = 3`) | A map or a set |
| **Resource address** | `resource[0]` / `resource[1]` | `resource["dev"]` / `resource["prod"]` |
| **Remove an item** | Index shifts → may destroy others ⚠️ | Only that key removed — safe ✓ |
| **Different configs per item** | No — all copies share the same block | Yes — use `each.value` for per-item config |
| **Best for** | N identical copies (replicas, spare VMs) | Named items (envs, regions, accounts) |

> **When in doubt → prefer `for_each`.** It is safer and more readable for production infrastructure.

---

## Slide 12 — Key Takeaways

### `count`
Creates N identical resources. Loop variable is `count.index` (starts at 0). Watch out for **index shift** when removing middle items.

### `for_each`
Creates N named resources. Accepts a map or set. Loop variables are `each.key` and `each.value`. Safe to remove any item — others are unaffected.

### `for`
Transforms data — does **NOT** create resources. `[ ]` = list, `{ }` = map. Use in `locals`, `outputs`, and to feed `for_each`.

### The Rule

```
Items have names?          →  for_each
Just need N copies?        →  count
Need to reshape data?      →  for expression
```

---

## Slide 13 — What We'll Build in the Demo

### Demo 01 — `count`: Three EC2 Instances
Create 3 identical EC2 instances. Use `count.index` in the Name tag. Reference one by index in an output.

### Demo 02 — `for_each`: S3 Buckets from a Map
Define a map of environments → configs. Create one bucket per env. Remove one env and show the isolated plan output.

### Demo 03 — `for` Expression in Outputs
Use a `for` expression to extract all bucket ARNs into a map output. Show the list → map transformation pattern.

---

## Quick Reference Cheatsheet

```hcl
# ── count ────────────────────────────────────────────────
resource "aws_instance" "web" {
  count         = 3
  instance_type = "t2.micro"
  tags = { Name = "web-${count.index}" }
}
# Address: aws_instance.web[0], web[1], web[2]

# ── for_each with set ─────────────────────────────────────
resource "aws_s3_bucket" "app" {
  for_each = toset(["dev", "stage", "prod"])
  bucket   = "myapp-${each.key}"
}
# Address: aws_s3_bucket.app["dev"], app["stage"], app["prod"]

# ── for_each with map ─────────────────────────────────────
resource "aws_instance" "env" {
  for_each      = { dev = "t2.micro", prod = "t3.small" }
  instance_type = each.value
  tags          = { Name = each.key }
}

# ── for expression (list → list) ──────────────────────────
locals {
  upper_envs = [ for e in var.envs : upper(e) ]
}

# ── for expression (list → map) ───────────────────────────
output "bucket_arns" {
  value = { for k, v in aws_s3_bucket.app : k => v.arn }
}

# ── for expression with filter ────────────────────────────
locals {
  prod_only = [ for e in var.envs : e if e != "dev" ]
}

# ── count = 0 trick (conditional resource) ────────────────
resource "aws_instance" "bastion" {
  count         = var.create_bastion ? 1 : 0
  instance_type = "t2.micro"
}
```

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| `for_each = var.envs` when `var.envs` is a plain list | `for_each = toset(var.envs)` |
| `value = aws_instance.web.public_ip` with count | `value = aws_instance.web[0].public_ip` |
| Using `for` expression inside a resource block as if it creates resources | Use `for_each` on the resource block itself |
| Removing a middle item from a `count` list | Switch to `for_each` for named resources |

---

*Notes match the slides in: `terraform_loops_with_icons.pptx`*
*Next topic: Dynamic Blocks*
