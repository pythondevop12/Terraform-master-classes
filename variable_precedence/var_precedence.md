# 🔢 Terraform — Variable Precedence (Deep Dive)
### Terraform Series — video 5 · @PythonDevOpsAcademy

---

## 🎯 What We'll Learn

- All the ways to pass variables in Terraform
- Which method wins when multiple are set (precedence order)
- `auto.tfvars` vs `tfvars` — what's the difference
- `TF_VAR_` environment variables — the hidden method
- Real-world dev/staging/prod pattern using `-var-file`
- Common mistakes and how to debug them

---


## 📊 All Ways to Pass Variables (Lowest → Highest Priority)

```
Priority 0 (SPECIAL) →  variable declared inside main.tf (hardcoded / no override)
Priority 1 (LOWEST)  →  default value in variables.tf
Priority 2           →  TF_VAR_ environment variables
Priority 3           →  terraform.tfvars
Priority 4           →  terraform.tfvars.json
Priority 5           →  *.auto.tfvars / *.auto.tfvars.json
Priority 6           →  -var-file flag on CLI
Priority 7 (HIGHEST) →  -var flag on CLI
```

> Rule: Higher priority ALWAYS wins over lower priority.

---
### Real-World Multi-Environment Pattern

```
terraform-project/
├── main.tf
├── variables.tf
├── terraform.tfvars      # dev (default)
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
```

```bash
# Deploy to dev
terraform apply -var-file="environments/dev.tfvars"

# Deploy to staging
terraform apply -var-file="environments/staging.tfvars"

# Deploy to prod
terraform apply -var-file="environments/prod.tfvars"
```

---


### Priority Position of `TF_VAR_`

```
Priority 1  →  default in variables.tf
Priority 2  →  TF_VAR_ environment variables  ← HERE
Priority 3  →  terraform.tfvars
Priority 4  →  terraform.tfvars.json
Priority 5  →  *.auto.tfvars
Priority 6  →  -var-file flag
Priority 7  →  -var flag  (HIGHEST)
```

> Used when: CI/CD systems inject secrets as environment variables.
> Never hardcode secrets in `.tfvars` files. Use `TF_VAR_` instead.

```bash
# GitLab CI / GitHub Actions example
export TF_VAR_db_password=$SECRET_FROM_VAULT
terraform apply -auto-approve
```

---

## Full Precedence — Visual Summary

```
┌──────────────────────────────────────────────────────┐
│            TERRAFORM VARIABLE PRECEDENCE             │
│                                                      │
│   7  -var flag                      ← HIGHEST   │
│   6  -var-file flag                                  │
│   5  *.auto.tfvars                                   │
│   4  terraform.tfvars.json                           │
│   3  terraform.tfvars                                │
│   2  TF_VAR_ environment variables                   │
│   1  default in variables.tf        ← LOWEST        │
│   0  hardcoded in resource          ← NOT OVERRIDABLE│
└──────────────────────────────────────────────────────┘
```

---


## Common Mistakes

### Mistake 1 — Expecting `tfvars` to override `-var`

```bash
# terraform.tfvars has env = "dev"
terraform apply -var="env=prod"
# Result: "prod" wins — -var always beats tfvars
```

### Mistake 2 — Multiple `auto.tfvars` files conflicting

```bash
# a-base.auto.tfvars    → env = "staging"
# b-override.auto.tfvars → env = "prod"
# Result: "prod" wins — alphabetically last wins
```

### Mistake 3 — Forgetting `TF_VAR_` is case-sensitive

```bash
export TF_VAR_Env="prod"   # Wrong — capital E
export TF_VAR_env="prod"   # Correct — must match variable name exactly
```

### Mistake 4 — `-var-file` not being specific enough

```bash
terraform apply -var-file="tfvars/prod"    # Wrong — no extension
terraform apply -var-file="tfvars/prod.tfvars"  # Correct
```

---

## When to Use What — Real World Guide

| Situation | Best Method |
|---|---|
| Local development defaults | `default` in `variables.tf` |
| Single environment project | `terraform.tfvars` |
| Multiple environments (dev/prod) | `-var-file` with separate `.tfvars` files |
| CI/CD pipeline secrets | `TF_VAR_` environment variables |
| Quick one-off override | `-var` flag |
| Shared team base config | `*.auto.tfvars` |

---

## Key Takeaways

```
1. Higher number = Higher priority = Wins
2. -var flag is KING — overrides everything
3. terraform.tfvars is auto-loaded — no flag needed
4. *.auto.tfvars is also auto-loaded — loaded alphabetically
5. TF_VAR_ = great for CI/CD secrets
6. -var-file = best for multi-environment setups
7. When in doubt: terraform apply -var="key=value" overrides all
```

---

## Interview Questions

**Q: Which has higher priority — `terraform.tfvars` or `-var` flag?**
> `-var` flag. It is always the highest priority.

**Q: What is the difference between `terraform.tfvars` and `*.auto.tfvars`?**
> Both are auto-loaded. `terraform.tfvars` must have that exact name.
> `*.auto.tfvars` can have any name ending in `.auto.tfvars`.
> `auto.tfvars` has higher priority.

**Q: How do you pass secrets in CI/CD without hardcoding in files?**
> Use `TF_VAR_` environment variables. Example: `export TF_VAR_db_password=$SECRET`

**Q: If two `.auto.tfvars` files set the same variable, which wins?**
> The file that is alphabetically LAST wins, since files are loaded in alphabetical order.

**Q: What happens if a variable has no default and is not provided anywhere?**
> Terraform will interactively prompt you to enter the value during `plan` or `apply`.

---

*Notes by PythonDevOps | video 5 | Terraform Variable Precedence*
