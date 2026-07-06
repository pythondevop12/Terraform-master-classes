# Terraform Dynamic Blocks — Theory Notes

> **Episode:** Terraform Dynamic Blocks | **Channel:** PythonDevOpsAcademy
> **Prerequisite:** Terraform Loops (count, for_each, for expressions)
> **AWS Region:** us-east-1

---

## Slide 1 — Introduction

Dynamic blocks let you generate repeated nested configuration blocks inside a resource — programmatically, from a variable.

**Key resources covered in demos:**
- `aws_security_group` — ingress / egress rules
- `aws_autoscaling_group` — tag blocks
- `aws_instance` — additional block patterns

---

## Slide 2 — What is a Dynamic Block?

In the last episode, `for_each` looped over **resources** — creating multiple separate EC2 instances or S3 buckets.

A dynamic block does the same thing but **one level deeper** — it loops over nested **blocks inside** a resource.

### Analogy

| Approach | What it does |
|---|---|
| `for_each` on a resource | Stamp out multiple EC2 instances |
| `dynamic` inside a resource | Stamp out multiple ingress rules inside one Security Group |

Same idea, different level.

### Where you use dynamic blocks

- `aws_security_group` — `ingress` / `egress` rules
- `aws_autoscaling_group` — `tag` blocks
- `aws_ecs_task_definition` — `volume` mounts
- `aws_lb_listener_rule` — `condition` blocks
- Any resource with repeated nested blocks

### What dynamic blocks cannot do

- ✗ Create top-level resources (use `for_each` on the resource)
- ✗ Replace `for_each` on a resource block
- ✗ Be used outside a resource, module, or provider

---

## Slide 3 — The Problem: Repeated Nested Blocks

**Scenario:** Create a Security Group with 3 ingress rules.

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
```

### Problems

- ✗ 3 identical `ingress` blocks
- ✗ Add a port → paste another block
- ✗ Change protocol → edit all three
- ✗ 10 rules = 10 copy-pasted blocks
- ✗ Violates DRY principle

> What if the ports came from a variable? We'd need dynamic blocks.

---

## Slide 4 — The Solution: Dynamic Blocks

Same 3 ingress rules — rewritten with a `dynamic` block:

```hcl
variable "ingress_rules" {
  default = [
    { port = 80,  cidr = "0.0.0.0/0" },
    { port = 443, cidr = "0.0.0.0/0" },
    { port = 22,  cidr = "10.0.0.0/8" },
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }
}
```

### Benefits

- ✓ One `dynamic` block handles all rules
- ✓ Add rule → update the variable list
- ✓ Clean, readable, reviewable
- ✓ Scales to any number of rules
- ✓ Config lives in variables — not in resource blocks

Adding a 4th rule = adding one item to the list. No changes to the resource block.

---

## Slide 5 — Syntax Walkthrough

```hcl
dynamic "ingress" {       # ① block label
  for_each = var.rules    # ② collection to iterate
  content {               # ③ body of each generated block
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = [ingress.value.cidr]
  }
}
```

### The three parts

| Part | What it does |
|---|---|
| `dynamic "ingress"` | The name of the nested block to generate. Must match the block label used in the resource schema. |
| `for_each = ...` | Same as `for_each` on a resource. Accepts a list, map, or set. |
| `content { }` | The body of each generated block. Arguments go here. |

### The iterator variable

Inside `content { }`, the iterator is **named after the dynamic block label**:

```hcl
dynamic "ingress" { ... }  →  use  ingress.value  and  ingress.key  inside content
dynamic "tag"     { ... }  →  use  tag.value      and  tag.key      inside content
```

---

## Slide 6 — The Iterator: `.value` and `.key`

The iterator exposes two attributes inside `content { }`:

| Attribute | What it contains |
|---|---|
| `<label>.key` | The index (for lists) or key (for maps). Usually not needed — most blocks use `.value`. |
| `<label>.value` | The current item from the collection. If iterating a list of objects, access fields with `.value.field_name`. |

### Example — iterating a list of objects

```hcl
# var.ingress_rules = [
#   { port = 80, cidr = "0.0.0.0/0" },
#   { port = 22, cidr = "10.0.0.0/8" },
# ]

dynamic "ingress" {
  for_each = var.ingress_rules      # list of objects
  content {
    from_port   = ingress.value.port   # access object field with .value.field
    to_port     = ingress.value.port
    cidr_blocks = [ingress.value.cidr]
  }
}
```

---

## Slide 7 — Custom Iterator Label

By default the iterator name equals the block label. Use `iterator =` to override it.

```hcl
# Default — iterator name = block label
dynamic "ingress" {
  for_each = var.rules
  content {
    from_port = ingress.value.port   # iterator name = "ingress"
  }
}

# Custom — cleaner name with iterator =
dynamic "ingress" {
  for_each = var.rules
  iterator = rule              # custom name
  content {
    from_port = rule.value.port   # much more readable!
  }
}
```

Use `iterator =` when the block label is long or ambiguous:

```hcl
dynamic "listener_rule" { iterator = rule  →  rule.value.path_pattern  (much nicer)
```

### Nested dynamic blocks

Dynamic blocks can be nested — `dynamic` inside `dynamic`:

```hcl
dynamic "ingress" {
  for_each = var.rules
  content {
    dynamic "timeouts" {            # nested dynamic block
      for_each = ingress.value.timeouts
      content { create = timeouts.value }
    }
  }
}
```

---

## Slide 8 — Real Example: AWS Security Group

Complete Security Group with dynamic ingress **and** egress rules:

```hcl
variable "ingress_rules" {
  default = [
    { port = 80,  cidr = "0.0.0.0/0" },
    { port = 443, cidr = "0.0.0.0/0" },
    { port = 22,  cidr = "10.0.0.0/8" },
  ]
}

variable "egress_rules" {
  default = [
    { port = 0, cidr = "0.0.0.0/0" },
  ]
}

resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = "-1"
      cidr_blocks = [egress.value.cidr]
    }
  }
}
```

> Adding a port = 1 item in the variable list. No changes to the resource block.

---

## Slide 9 — `for_each` vs `dynamic` block

This is the most important distinction to understand.

| | `for_each` on a resource | `dynamic` inside a resource |
|---|---|---|
| **Creates** | Multiple separate resources | Multiple nested blocks inside 1 resource |
| **Used on** | The `resource` block itself | A nested block inside a resource |
| **Result in state** | N independent state entries | 1 resource with N nested blocks |
| **Example** | 3 EC2 instances, 3 S3 buckets | 3 ingress rules in one Security Group |

```hcl
# for_each on resource → 2 separate EC2 instances
resource "aws_instance" "web" {
  for_each      = toset(["a", "b"])
  instance_type = "t2.micro"
}
# Creates: aws_instance.web["a"]  and  aws_instance.web["b"]

# dynamic inside resource → 1 SG with 3 ingress rules
resource "aws_security_group" "web" {
  dynamic "ingress" {
    for_each = [80, 443, 22]
    content { from_port = ingress.value }
  }
}
# Creates: 1 Security Group with 3 ingress rules inside it
```

> **Rule:** Use `for_each` to create multiple resources. Use `dynamic` to create multiple nested blocks inside one resource.

---

## Slide 10 — Common Patterns (1 & 2)

### Pattern 1 — List of port numbers

```hcl
variable "ports" { default = [80, 443, 8080] }

dynamic "ingress" {
  for_each = var.ports
  content {
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Pattern 2 — Map of tag blocks (e.g. Auto Scaling Group)

```hcl
variable "tags" { default = { Env = "prod", Team = "ops" } }

dynamic "tag" {
  for_each = var.tags
  content {
    key   = tag.key
    value = tag.value
  }
}
```

> Use `tag.key` and `tag.value` to dynamically stamp tags from any map variable.

---

## Slide 11 — Common Patterns (3)

### Pattern 3 — Conditional block: include or exclude with `if`

```hcl
variable "allow_ssh" {
  type    = bool
  default = true
}

dynamic "ingress" {
  for_each = var.allow_ssh ? [22] : []   # [22] = include, [] = exclude
  content {
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
}
```

### How it works

| Variable value | `for_each` | Result |
|---|---|---|
| `var.allow_ssh = true` | `for_each = [22]` | 1 ingress block generated |
| `var.allow_ssh = false` | `for_each = []` | 0 ingress blocks (no SSH rule) |

> This is cleaner than `count = 0` — an empty list generates zero blocks with no state side-effects.

---

## Slide 12 — Common Mistakes

| Mistake | Fix |
|---|---|
| Typo in block label: `dynamic "ingresss"` | Must match the resource schema exactly: `dynamic "ingress"` |
| `from_port = ingress.port` — missing `.value` | `from_port = ingress.value.port` |
| `dynamic "aws_instance"` — trying to create a resource | Use `for_each` on the `resource` block instead |

---

## Slide 13 — Key Takeaways

### What it is
A `dynamic` block generates repeated nested blocks inside a resource — like `for_each`, but for block arguments, not for resources.

### Syntax
```hcl
dynamic "<block-label>" {
  for_each = <collection>
  content {
    <block args using label.value>
  }
}
```

### Iterator
Inside `content { }`, use `<label>.value` to access the current item and `<label>.key` for the index. Override the iterator name with `iterator =`.

### Best for
Security Group ingress/egress rules, ASG tag blocks, ECS volume mounts, and any resource with repeated nested configuration blocks.

### The Rule
```
for_each on resource  =  multiple resources
dynamic inside resource  =  multiple nested blocks in one resource
```

---

## Slide 14 — What We'll Build in the Demo

### Demo 01 — Dynamic ingress rules: Security Group
Define a list of port objects in a variable. Use a `dynamic "ingress"` block to stamp out one rule per port. Add and remove ports without touching the resource block.

### Demo 02 — Conditional block: SSH toggle
Use `dynamic "ingress" { for_each = var.allow_ssh ? [22] : [] }` to include the SSH rule only when a boolean variable is `true`.

### Demo 03 — Dynamic tag blocks: Auto Scaling Group
Use a `dynamic "tag"` block to stamp tags from a map variable onto an Auto Scaling Group — one dynamic block replaces N identical tag blocks.

---

## Quick Reference Cheatsheet

```hcl
# ── Basic dynamic block ───────────────────────────────────────────────────
dynamic "ingress" {
  for_each = var.ingress_rules          # list, map, or set
  content {
    from_port   = ingress.value.port    # <label>.value.<field>
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = [ingress.value.cidr]
  }
}

# ── Custom iterator name ──────────────────────────────────────────────────
dynamic "ingress" {
  for_each = var.rules
  iterator = rule                       # override iterator name
  content {
    from_port = rule.value.port         # now use rule.value
  }
}

# ── Conditional block (boolean flag) ─────────────────────────────────────
dynamic "ingress" {
  for_each = var.enable_https ? [443] : []
  content {
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── Map of tag blocks ─────────────────────────────────────────────────────
dynamic "tag" {
  for_each = var.tags                   # map: { Env="prod", Team="ops" }
  content {
    key   = tag.key
    value = tag.value
  }
}

# ── Nested dynamic blocks ─────────────────────────────────────────────────
dynamic "ingress" {
  for_each = var.rules
  content {
    dynamic "timeouts" {
      for_each = ingress.value.timeouts
      content { create = timeouts.value }
    }
  }
}
```

---
