# CS686 Assignment 7 — Custom AMI + AWS Infrastructure with Packer & Terraform

## Overview

This project provisions a production-style AWS environment using two tools:

| Tool | Purpose |
|------|---------|
| **Packer** | Builds a custom Amazon Linux 2023 AMI with Docker pre-installed and your SSH public key baked in |
| **Terraform** | Provisions a VPC (public + private subnets), a bastion host, and 6 private EC2 instances using the custom AMI |

### Architecture Diagram

```
Internet
    │
    ▼
Internet Gateway
    │
┌───┴──────────────────────────────┐
│  VPC  10.0.0.0/16                │
│                                  │
│  ┌───────────────────────────┐   │
│  │  Public Subnet            │   │
│  │  10.0.1.0/24  (us-east-1a)│   │
│  │  10.0.2.0/24  (us-east-1b)│   │
│  │                           │   │
│  │  ┌─────────────┐          │   │
│  │  │  Bastion    │ ◄── SSH  │   │
│  │  │  (your IP   │   (port  │   │
│  │  │   only)     │   22)    │   │
│  │  └──────┬──────┘          │   │
│  │         │ NAT GW          │   │
│  └─────────┼─────────────────┘   │
│            │                     │
│  ┌─────────┼─────────────────┐   │
│  │  Private Subnet           │   │
│  │  10.0.10.0/24 (us-east-1a)│   │
│  │  10.0.11.0/24 (us-east-1b)│   │
│  │                           │   │
│  │  ┌────┐ ┌────┐ ┌────┐     │   │
│  │  │ EC2│ │ EC2│ │ EC2│     │   │
│  │  │ #1 │ │ #2 │ │ #3 │     │   │
│  │  └────┘ └────┘ └────┘     │   │
│  │  ┌────┐ ┌────┐ ┌────┐     │   │
│  │  │ EC2│ │ EC2│ │ EC2│     │   │
│  │  │ #4 │ │ #5 │ │ #6 │     │   │
│  │  └────┘ └────┘ └────┘     │   │
│  └───────────────────────────┘   │
└──────────────────────────────────┘
```

---

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/downloads) ≥ 1.10
- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ 1.6
- AWS CLI configured (`aws configure`) with sufficient IAM permissions
- An existing **EC2 Key Pair** in your AWS account

---

## Part A — Build the Custom AMI with Packer

### What it does
- Starts from the latest **Amazon Linux 2023** AMI
- Installs **Docker** via `yum` and enables it as a service
- Injects your **SSH public key** into `~ec2-user/.ssh/authorized_keys`
- Registers the result as a new AMI in your account

### Steps

```bash
cd Assignment7/packer

# Initialize Packer plugins
packer init amazon-linux.pkr.hcl

# (Optional) Validate the template
packer validate amazon-linux.pkr.hcl

# Build the AMI
packer build amazon-linux.pkr.hcl
```

> **To use a different SSH public key:**
> ```bash
> packer build -var 'ssh_public_key=ssh-rsa AAAA...' amazon-linux.pkr.hcl
> ```

After a successful build, Packer prints the new **AMI ID** — copy it, you will need it for Terraform.

**Screenshot Packer build output:**
<img width="1178" height="566" alt="Screenshot 2026-03-30 at 2 00 43 PM" src="https://github.com/user-attachments/assets/999bcd82-0f51-4ffb-b209-cf50c7412552" />


---

## Part B — Provision AWS Infrastructure with Terraform

### Resource summary

| Resource | Count | Details |
|----------|-------|---------|
| VPC | 1 | `10.0.0.0/16` |
| Public subnets | 2 | `10.0.1.0/24`, `10.0.2.0/24` |
| Private subnets | 2 | `10.0.10.0/24`, `10.0.11.0/24` |
| Internet Gateway | 1 | Attached to VPC |
| NAT Gateway | 1 | In public subnet, used by private instances |
| Bastion host | 1 | Public subnet — SSH allowed **only from your IP** |
| Private EC2 instances | 6 | Private subnets — custom Packer AMI |

### Steps

#### 1. Edit `terraform.tfvars`

```bash
cd Assignment7/terraform
```

Open [terraform/terraform.tfvars](terraform/terraform.tfvars) and set:

```hcl
key_name      = "your-key-pair-name"     # EC2 Key Pair already in AWS
my_ip_cidr    = "YOUR.IP.HERE/32"        # curl https://checkip.amazonaws.com/
custom_ami_id = "ami-XXXXXXXXXXXXX"      # AMI ID from Packer output
```

#### 2. Initialize Terraform

```bash
terraform init
```

#### 3. Preview the plan

```bash
terraform plan
```

#### 4. Apply

```bash
terraform apply
```

Type `yes` when prompted. After ~5 minutes, Terraform prints the outputs:

```
bastion_public_ip     = "3.X.X.X"
private_instance_ips  = ["10.0.10.X", "10.0.10.X", ...]
ssh_to_bastion        = "ssh -A -i <key.pem> ec2-user@3.X.X.X"
ssh_tunnel_example    = "ssh -J ec2-user@3.X.X.X ec2-user@10.0.10.X"
```

**Screenshot — Terraform apply output:**

<img width="545" height="313" alt="Screenshot 2026-03-30 at 3 32 49 PM" src="https://github.com/user-attachments/assets/1136d805-a329-45c3-b4d8-761b6f2e754e" />


**Screenshot — AWS Console — EC2 instances:**

<img width="1093" height="195" alt="Screenshot 2026-03-30 at 3 34 21 PM" src="https://github.com/user-attachments/assets/abe1faf9-08de-488f-9678-b07e2239dee9" />


**Screenshot — AWS Console — VPC subnets:**

<img width="1103" height="673" alt="Screenshot 2026-03-30 at 3 35 28 PM" src="https://github.com/user-attachments/assets/1f29c1dc-4c46-4147-911c-ee20e70a011a" />


---

## Connecting to Private Instances via the Bastion

### Option 1 — SSH ProxyJump (recommended)

```bash
ssh -i your-private-key.pem \
    -J ec2-user@<BASTION_PUBLIC_IP> \
    ec2-user@<PRIVATE_INSTANCE_IP>
```

### Option 2 — SSH Agent Forwarding

**Step 1 — Add your key to the SSH agent:**
```bash
ssh-add your-private-key.pem
```

**Step 2 — SSH into the bastion with agent forwarding:**
```bash
ssh -A -i your-private-key.pem ec2-user@<BASTION_PUBLIC_IP>
```

**Step 3 — From inside the bastion, SSH into any private instance:**
```bash
ssh ec2-user@<PRIVATE_INSTANCE_IP>
```

### Option 3 — `~/.ssh/config` shortcut

Add this to your local `~/.ssh/config`:

```
Host bastion
  HostName <BASTION_PUBLIC_IP>
  User ec2-user
  IdentityFile ~/path/to/your-private-key.pem
  ForwardAgent yes

Host private-*
  User ec2-user
  IdentityFile ~/path/to/your-private-key.pem
  ProxyJump bastion
```

Then simply:
```bash
ssh private-1   # where private-1's IP is configured elsewhere, or use the IP directly
ssh -J bastion ec2-user@10.0.10.X
```

**Screenshot — SSH into bastion then private instance:**

<img width="552" height="200" alt="Screenshot 2026-03-30 at 3 37 00 PM" src="https://github.com/user-attachments/assets/0354187e-e701-47a1-949f-ad9cbb1ddb91" />


---

## Verifying Docker on Private Instances

After SSH-ing into any private instance:

```bash
docker --version
# Docker version 25.x.x, build ...

docker run hello-world
# Hello from Docker!
```

**Screenshot — Docker running on private instance:**

<img width="594" height="197" alt="Screenshot 2026-03-30 at 3 37 20 PM" src="https://github.com/user-attachments/assets/b38601fa-ddad-497b-9d6c-958365d22fd1" />
<img width="610" height="421" alt="Screenshot 2026-03-30 at 3 37 52 PM" src="https://github.com/user-attachments/assets/bdb0f0cf-4ba6-4b00-a5f2-1390069c87ae" />


---

## Teardown

To destroy all provisioned AWS resources (avoids ongoing charges):

```bash
cd Assignment8/terraform
terraform destroy
```

<img width="307" height="143" alt="Screenshot 2026-03-30 at 3 43 37 PM" src="https://github.com/user-attachments/assets/65a47c56-7cef-44ea-bba6-6b23026a51b6" />


> **Note:** The custom AMI and its snapshot must be deregistered manually via the AWS Console or CLI — Terraform does not manage Packer-built AMIs.

---

## Project Structure

```
Assignment8/
├── packer/
│   ├── amazon-linux.pkr.hcl      # Packer template
│   └── scripts/
│       └── install_docker.sh     # Docker installation script
├── terraform/
│   ├── main.tf                   # Root module — wires together sub-modules
│   ├── variables.tf              # Input variable declarations
│   ├── outputs.tf                # Output values (IPs, SSH commands)
│   ├── terraform.tfvars          # Your values (key pair, IP, AMI ID)
│   └── modules/
│       ├── vpc/                  # VPC, subnets, IGW, NAT GW, route tables
│       ├── bastion/              # Bastion host + restricted security group
│       └── private_instances/    # 6 private EC2 instances + security group
└── README.md
```
