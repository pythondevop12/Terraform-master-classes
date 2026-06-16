# Terraform Data Types

**Series:** Terraform Series — PythonDevOpsAcademy  
**Topics:** Primitives · Collections · Structural Types

---

## What We'll Cover

1. **Primitive Types** — `string` · `number` · `bool`
2. **Collection Types** — `list` · `set` · `map`
3. **Structural Types** — `object` · `tuple`
4. **Type Constraints** — `any` · typed variables

---

## 01 — Primitive Types

Primitive types are the building blocks of all Terraform variables.

### `string`

A sequence of Unicode characters. Used for names, ARNs, regions, tags.

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

### `number`

Whole or fractional numeric value. Used for instance counts, ports, sizes.

```hcl
variable "instance_count" {
  type    = number
  default = 2
}
```

### `bool`

`true` or `false`. Used for feature flags and conditionals.

```hcl
variable "enable_dns" {
  type    = bool
  default = true
}
```

---

## 02 — Collection Types

Collection types hold multiple values of the same type — essential for loops.

### `list(type)`

- Ordered — order is preserved
- Indexed — access by position `[0]`
- Duplicates allowed
- Used with `count` loop

```hcl
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Access:
var.azs[0]  # "us-east-1a"
```

### `set(type)`

- Unordered — no guaranteed order
- No duplicates — unique values only
- No index access
- Used with `for_each` loop

```hcl
variable "ports" {
  type    = set(number)
  default = [80, 443, 8080]
}
# Used directly with for_each
```

### `map(type)`

- Key-value pairs
- Keys are always strings
- Values must be the same type
- Used with `for_each` loop

```hcl
variable "tags" {
  type = map(string)
  default = {
    env  = "prod"
    team = "devops"
  }
}
```

---

## list vs set vs map — When to Use Which?

| Feature              | `list`   | `set`    | `map`        |
|----------------------|----------|----------|--------------|
| Ordered?             | Yes      | No       | No           |
| Allows duplicates?   | Yes      | No       | Yes (values) |
| Access by index?     | Yes      | No       | By key       |
| Works with `count`?  | Yes      | No       | No           |
| Works with `for_each`? | No     | Yes      | Yes          |

> **Pro tip:** `for_each` requires a `set` or `map`. If you have a `list`, convert it with `toset()`.

---

## 03 — Structural Types

Structural types let you group mixed types into a single variable.

### `object({ ... })`

Named attributes with mixed types. Like a struct — each key has its own type.

```hcl
variable "server" {
  type = object({
    name    = string
    port    = number
    enabled = bool
  })
  default = {
    name    = "web"
    port    = 80
    enabled = true
  }
}
```

### `tuple([ ... ])`

Fixed-length, mixed-type sequence. Positional — order and length are fixed.

```hcl
variable "record" {
  type = tuple([
    string,
    number,
    bool
  ])
  default = [
    "web-server",
    80,
    true
  ]
}
```

---

## 04 — Type Constraints

### `any`

Skips type checking. Terraform infers the type from the value at runtime. Avoid in production — be explicit.

```hcl
variable "data" {
  type = any
}
```

> **Warning:** Use `any` only when absolutely necessary.

### Best Practices

- Always declare explicit types in variables
- Use `list` when order matters and you need indexes
- Use `set` when values must be unique (for `for_each`)
- Use `map` for key-value lookups (for `for_each`)
- Use `object` when attributes have different types
- Avoid `any` — explicit types catch errors early

---

## Quick Reference Cheatsheet

| Type | Syntax |
|------|--------|
| `string` | `type = string` |
| `number` | `type = number` |
| `bool` | `type = bool` |
| `list(string)` | `type = list(string)` |
| `set(string)` | `type = set(string)` |
| `map(string)` | `type = map(string)` |
| `object({...})` | `type = object({ name = string })` |
| `tuple([...])` | `type = tuple([string, number])` |
| `any` | `type = any` — avoid in production |
