# Terraform EC2 with UserData 🚀

> **YouTube Video 6** — Deploy an EC2 instance with a bootstrap script using Terraform

---

## 📁 Project Structure

```
terraform-ec2/
├── main.tf          # EC2 instance + security group
├── variables.tf     # Input variables
├── outputs.tf       # Public IP & DNS
└── userdata.sh      # Bootstrap script (installs nginx)
```

---

## 🧰 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured (`aws configure`)
- An AWS account with EC2 permissions

---

## ⚙️ What This Does

1. Creates a **Security Group** — opens port 22 (SSH) and port 80 (HTTP)
2. Launches an **EC2 instance** (Amazon Linux 2, t3.micro)
3. Runs **userdata.sh** on first boot — installs nginx and serves a webpage

---

## 🚀 How to Deploy

```bash
# 1. Clone or download the project
cd terraform-ec2

# 2. Initialize Terraform
terraform init

# 3. Preview the plan
terraform plan

# 4. Apply (type 'yes' when prompted)
terraform apply
```

After apply completes, you'll see:

```
Outputs:
  instance_id = "i-0a1b2c3d4e5f67890"
  public_ip   = "54.123.45.67"
  public_dns  = "ec2-54-123-45-67.compute-1.amazonaws.com"
```

Open `http://<public_ip>` in your browser — you should see the nginx page! 🎉

---

## 📝 Key Concepts

### `user_data = file("userdata.sh")`
Terraform reads `userdata.sh` at plan time and passes it to EC2 as a base64-encoded bootstrap script. It runs **once** on first boot as root.

### `set -ex` in userdata.sh
- `-e` → exit immediately on any error
- `-x` → log every command to `/var/log/cloud-init-output.log`

### Debug UserData Logs
```bash
ssh -i your-key.pem ec2-user@<public_ip>
sudo cat /var/log/cloud-init-output.log
```

---

## 🔧 Customize Variables

You can override defaults without editing files:

```bash
terraform apply \
  -var="aws_region=ap-south-1" \
  -var="instance_type=t3.small"
```

Or create a `terraform.tfvars` file:

```hcl
aws_region    = "ap-south-1"
instance_type = "t3.small"
```

---

## 🧹 Cleanup

```bash
terraform destroy
```

> ⚠️ This will delete all resources created by this project.

---

## 📺 Video Series

| Video | Topic |
|-------|-------|
| 1 | Terraform Basics & Installation |
| 2 | Providers & Authentication |
| 3 | Resources & State |
| 4 | Variables & Outputs |
| 5 | Modules |
| **6** | **EC2 with UserData** ← you are here |

---
