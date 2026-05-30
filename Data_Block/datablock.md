# 📦 Terraform — Data Sources

---

## The One-Line Concept

> **Data Sources = Read-Only lookups. Terraform asks "what exists?" — it never creates, changes, or deletes anything.**

Think of it like a **Google search inside your Terraform config** — you're fetching information, not building something.

---

## The Core Difference (Burn This Into Memory)

| | `resource` | `data` |
|---|---|---|
| **What it does** | Creates & manages infra | Reads existing infra |
| **Terraform controls it?** | Yes | No |
| **In state file?** |  Full lifecycle | Cached only |
| **Can destroy it?** |  Yes |  Never |

**Beginner analogy:** A `resource` is buying a house. A `data source` is looking up a neighbour's address — you're not buying their house, just reading their info.

**Advanced analogy:** Resources are imperative writes; data sources are declarative reads that resolve at graph evaluation time.

---

## Syntax (Dead Simple)

```
data "<TYPE>" "<NAME>" {
  <filter arguments>
}
```

Reference it anywhere in your config as:
```
data.<TYPE>.<NAME>.<ATTRIBUTE>
```

---

## How It Works Internally

```
terraform plan
     │
     ▼
① Terraform evaluates filter arguments
     │
     ▼
② Calls provider's READ API
     │
     ▼
③ Provider returns matching attributes
     │
     ▼
④ Those attributes are available in your config
     │
     ▼
⑤ Zero infrastructure changes happen
```

**Timing:** Data sources are read at **plan time** by default.
If the data source depends on a resource being created first → Terraform defers it to **apply time** (auto in v0.13+, or force with `depends_on`).

---

##  Filters — How You Tell It What to Fetch

Data sources don't just grab everything — you narrow it down using filters.

| Method | When to use |
|---|---|
| Direct ID (`instance_id = "i-abc"`) | You know exactly what you want |
| `filter` block with name/values | Searching by tags, names, properties |
| Boolean flags (`most_recent = true`) | Want the latest version of something |
| Tag-based lookup | Searching by `Name` or `Environment` tag |

**Gotcha:** If your filter matches multiple results but the data source expects one → **Terraform throws an error.** Always write precise filters.

---

##  5 Core Use Cases

### 1.  Reference Infrastructure You Didn't Create
Someone else's VPC, a manually created security group, a shared S3 bucket — look it up, don't recreate it.

### 2.  Dynamic Values That Change Over Time
AMI IDs, SSL cert ARNs, availability zones — these change. Hardcoding them breaks things. Data sources always fetch the current value.

### 3. 🔗 Cross-Stack Communication (`terraform_remote_state`)
Infrastructure split across multiple Terraform configs? One stack reads the outputs of another using remote state.

### 4.  Secrets (No Hardcoding!)
Pull passwords, tokens, API keys from AWS Secrets Manager, Vault, or SSM Parameter Store directly into your config.

### 5.  Local Files & Templates
Read a startup script or JSON config from your filesystem and inject it into a resource.

---

##  `terraform_remote_state` — Advanced Cross-Stack Pattern

This is a **built-in** data source (no provider needed) that reads the **state file of another Terraform config** and exposes its outputs.

**When to use it:**
You've split infra into layers (network layer → app layer → database layer). Each layer is a separate Terraform config. Lower layers export outputs; upper layers read them via `terraform_remote_state`.

**Supported backends:** S3, GCS, Terraform Cloud, Azure Blob, and more.

---

##  `depends_on` — Controlling Read Order

Terraform builds a dependency graph automatically. But sometimes it can't infer that a data source must wait for a resource to be created first.

**When you need it:** A data source tries to read something that a `resource` in the same config will create.

**Without it:** Terraform reads the data source too early → error or stale data.
**With it:** Terraform waits for the resource to exist before reading the data source.

>  **Advanced note:** Overusing `depends_on` on data sources forces them to apply-time resolution, which can slow down plans. Use it only when the implicit dependency can't be detected by Terraform.

---

##  Scope Inside Modules

| Location | Accessible from |
|---|---|
| Root module | Entire configuration |
| Inside a module | Only that module |
| Module → outside | Must pass value as a module output |

Data sources are **not shared** across module boundaries automatically.

---

## Refresh Behaviour

Every `terraform plan` re-reads all data sources fresh. This means:

- You always get up-to-date values
- If the external resource was deleted, your next plan will **fail**
- If a new AMI matches your filter, Terraform may propose changes to resources using that AMI

> **Advanced note:** In large configs with many data sources, this can slow down plans because every data source makes an API call. Use targeted plans or minimize redundant lookups.

---

## Data Sources & State

Data sources are **not lifecycle-managed** in state. Terraform only caches the last-read result for reference — it does not track them for create/update/destroy.

| Thing | Resource | Data Source |
|---|---|---|
| Written to state | Full object | Cached result only |
| `terraform destroy` removes it |  Yes | No — it only forgets the cache |
| Drifts detected | Yes | No — re-read on every plan |

---

## Provider Dependency

Every data source belongs to a provider (AWS, GCP, Azure, etc.). The provider must be **configured** before any of its data sources can be used. Each provider exposes both `resource` types and `data` types.

Exception: a few data sources are **built-in** to Terraform itself (`terraform_remote_state`, `terraform_workspace`) and need no provider.

---

##  Quick Mental Model

```
Does Terraform own it?
        │
       YES → resource block
        │
        NO → data block
```

```
Is the value dynamic / outside your config?
        │
       YES → data block
        │
        NO → variable or local
```

---

##  Summary

| Concept | Key Point |
|---|---|
| Purpose | Read external/existing values without managing them |
| Keyword | `data` |
| Evaluated | Plan time (or apply time if depends on a resource) |
| In state | Cached only — no lifecycle |
| Filters | Must be precise — ambiguous filters cause errors |
| Cross-stack | Use `terraform_remote_state` |
| Secrets | Use provider-specific data sources (Vault, SSM, Secrets Manager) |
| Modules | Local scope — must output values to share |

> **One-liner to remember:** *Data sources let Terraform ask questions about the world — resources are Terraform's answers.*
