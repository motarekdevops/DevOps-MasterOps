# MasterOps

**The world's first dedicated bootstrap framework for DevOps engineers.** One command turns a fresh server or a new project into a fully provisioned, production-ready environment — the way `composer create-project laravel/laravel` gives you a working Laravel skeleton, MasterOps gives a DevOps engineer a working infrastructure skeleton, end to end.

```bash
sudo apt update && sudo apt install masterops
masterops new my-project --preset=laravel-postgres-react
```

No engineer should start a new project or join a new server by writing VPC code, Nginx configs, or CI pipelines from scratch again. MasterOps installs the scaffolding. The engineer only edits variables and decides what actually runs.

Where other tools give you scattered scripts or ad-hoc Ansible playbooks, MasterOps packages the entire DevOps setup lifecycle — infra, stacks, web server, CI, security, backups — into one versioned, installable, idempotent CLI. That's the gap it fills: DevOps engineers have never had a `create-project`-style tool built specifically for their own workflow, the way frontend and backend engineers have had for years.

---

## Current status: v0.1.3 (MVP, in progress)

MasterOps is real and installable today via a private APT repository, with a working CLI and a full Laravel + PostgreSQL + React preset that provisions and starts Nginx end to end. It is under active development — Terraform infrastructure modules (VPC, Subnets, Security Groups, IAM, EC2, ALB) are the next major piece being wired in, per the roadmap below.

```bash
masterops --version   # masterops v0.1.3
masterops doctor       # pre-flight server readiness check
```

---

## 1. Why this exists

Every new project or new hire at a company repeats the same setup work: VPC, subnets, security groups, IAM, Docker, Nginx, CI/CD, server hardening — all rebuilt by hand, differently, every time. MasterOps turns that repeated setup into a single installable package with reusable, versioned modules.

**Core principle:** MasterOps prepares everything. It starts nothing automatically. No container runs, no service starts, until the engineer explicitly says so. The engineer stays in control of what's running on the server so resource usage and blast radius are always a deliberate choice, never a side effect of installation.

---

## 2. Design principles

1. **Installable, not clonable.** Distributed as a real `.deb` package via a private APT repository — not a `git clone` and a setup script.
2. **Modular stacks.** Every technology (Postgres, Laravel, React, Nginx, Kubernetes...) lives in its own independent, versioned module. Adding or changing one stack never touches another.
3. **Presets, not manual assembly.** A preset (e.g. `laravel-postgres-react`) is a YAML file that wires together the modules a typical project needs, so the engineer runs one command instead of assembling pieces.
4. **Nothing auto-starts.** Installing a stack prepares config and compose files. Starting a service is always a separate, explicit command.
5. **Idempotency everywhere.** Every script in every module must be safe to run twice. This is what makes the tool trustworthy enough to run against a live server.
6. **One `main.tf` to edit.** All Terraform modules are pre-wired; the engineer only ever touches `variables.tf` and `terraform.tfvars`. *(Terraform layer: in progress — see roadmap.)*

---

## 3. Repository structure

```
masterops/
│
├── bin/masterops                     # CLI entrypoint
│
├── cli/
│   ├── commands/
│   │   ├── new.sh                    # masterops new <project>
│   │   ├── add.sh                    # masterops add postgres|redis|nginx
│   │   ├── start.sh                  # masterops start <service>   (explicit only)
│   │   ├── nginx.sh                  # masterops nginx --start     (interactive domain setup)
│   │   ├── deploy.sh                 # masterops deploy --env=production
│   │   ├── doctor.sh                 # pre-flight server checks
│   │   ├── diff.sh                   # drift detection
│   │   ├── backup.sh                 # manual/triggered backup run
│   │   └── upgrade.sh                # bump stack versions per project
│   └── lib/                          # shared helpers: logging, prompts, validation
│
├── terraform/                        # shipped: VPC/EC2/IAM/S3, Route53 optional
│   ├── main.tf                       # the ONLY file engineers wire modules in
│   ├── variables.tf                  # the ONLY file engineers edit day-to-day
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                      # VPC, public/private subnets, IGW, route tables
│       ├── ec2/                      # security group, instance, Ubuntu AMI lookup
│       ├── iam/                      # least-privilege EC2 instance role + profile
│       ├── s3/                       # encrypted, versioned, private-by-default bucket
│       └── route53/                  # optional -- only created if domain_name is set
│
├── stacks/
│   ├── database/
│   │   ├── postgres/
│   │   └── mysql/
│   │
│   ├── backend/
│   │   ├── laravel/
│   │   └── python3/
│   │
│   ├── frontend/
│   │   └── reactjs/
│   │
│   ├── runtime/
│   │   ├── docker/
│   │   ├── kubernetes/
│   │   └── helm/                     # standard Helm chart file structure
│   │
│   ├── webserver/
│   │   └── nginx/                    # native server install, not just containerized
│   │
│   ├── process/
│   │   ├── cron/                     # managed cron job templates
│   │   └── supervisor/               # supervisor job templates
│   │
│   ├── security/
│   │   └── bash-checks/              # security check bash scripts
│   │
│   ├── backup/
│   │   └── s3-daily/                 # daily backup to S3
│   │
│   └── monitoring/
│       └── alerts/                   # health alerts via email / Telegram
│
├── templates/
│   └── github-actions/
│       ├── laravel-ci.yml
│       ├── react-ci.yml
│       └── terraform-ci.yml
│
├── presets/
│   ├── laravel-postgres-react.yaml
│   ├── laravel-mysql.yaml
│   └── python-postgres.yaml
│
├── packaging/
│   ├── build-deb.sh                  # builds the .deb via fpm
│   ├── upload-package.sh             # publishes the .deb to the Buildkite Package Registry
│   └── debian/                       # postinstall scripts / fpm control files
│
└── masterops.yaml                    # generated per-project: records stack versions in use
```

---

## 4. Full module list

| Category | Modules | Status |
|---|---|---|
| Infra (Terraform) | VPC, EC2 (+ security group), IAM (instance role), S3 (encrypted, private), Route53 (optional DNS) | Shipped |
| Scripting | Bash helper library shared across all stacks | Shipped |
| Databases | PostgreSQL, MySQL (container + native install for both) | Shipped |
| Backend | Laravel (PHP, container + native), Python3 | Laravel shipped, Python3 planned |
| Frontend | ReactJS | Shipped |
| Containers | Docker, Kubernetes, Helm (standard chart structure) | Docker compose fragments shipped, K8s/Helm planned |
| Web server | Nginx (native install on the server, not container-only) | Shipped, interactive domain setup |
| Process management | Cron jobs, Supervisor jobs | Planned |
| Security | Bash-based security check scripts | Planned |
| Backup | Daily backup job to S3 | Planned |
| Monitoring / Alerts | Server health checks pushed to email / Telegram | Planned |
| Diagnostics | `masterops doctor` (pre-install server readiness check) | Shipped |
| Consistency | `masterops diff` (drift detector: local config vs. live server) | Planned |
| Secrets | Unified `.env.vault` layer (age/sops-encrypted), read by every stack | Planned |
| Versioning | `masterops.yaml` per-project stack version lock + `masterops upgrade` | Planned |

---

## 5. Command reference (target)

```bash
masterops new <project> --preset=<preset-name>   # scaffold a new project locally
masterops add <stack>                             # add a stack to an existing project
masterops start <service>                         # explicitly start a service/container
masterops nginx --start                           # interactive Nginx vhost + SSL setup
masterops doctor                                  # check server readiness before install
masterops diff                                    # show drift between local config and server
masterops deploy --env=<environment>               # provision + deploy to a server
masterops backup run                              # trigger an on-demand backup
masterops upgrade                                 # bump a project's stacks to newer versions
```

---

## 6. Distribution

MasterOps ships as a real Debian package, built and published automatically on every push via Buildkite CI, through a self-hosted Buildkite Package Registry:

```bash
curl -fsSL "https://packages.buildkite.com/mohamed-tarek/masterops/gpgkey" | sudo gpg --dearmor -o /etc/apt/keyrings/mohamed-tarek_masterops-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/mohamed-tarek_masterops-archive-keyring.gpg] https://packages.buildkite.com/mohamed-tarek/masterops/any/ any main" | sudo tee /etc/apt/sources.list.d/buildkite-mohamed-tarek-masterops.list

sudo apt update && sudo apt install masterops
```

Every commit to `main` triggers a Buildkite pipeline that builds the `.deb` with `fpm` and publishes it straight to the registry — no manual release step.

---

## 7. Infrastructure (Terraform)

Terraform provisions the AWS infrastructure a project runs on: a VPC with public/private subnets, an EC2 instance with a least-privilege IAM role, an encrypted S3 bucket, and (optionally) DNS records in an existing Route53 hosted zone.

**This step always runs on the engineer's own machine, never on a server.** `masterops terraform --start` refuses to run if it detects it's on a live EC2 instance (it checks the AWS instance metadata service), and asks for manual confirmation before doing anything.

```bash
masterops terraform --start   # copies the Terraform module tree into ./terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars   # done automatically by --start
# edit terraform.tfvars: project_name, key_name, allowed_ssh_cidr, domain_name...
terraform init
terraform plan
terraform apply
```

Once `apply` finishes, take the public IP from the output, SSH into the new server, and run `sudo apt install masterops -y` to continue setup on the server itself (Nginx, Docker, app stacks).

**What each module does:**

| Module | Creates | Notes |
|---|---|---|
| `vpc` | VPC, public + private subnets, Internet Gateway, route tables | One public/private subnet pair per AZ in `var.azs` |
| `ec2` | Security group (22/80/443 inbound), instance, Ubuntu 24.04 AMI lookup | AMI resolved via Canonical's official SSM parameter, not a name filter, so it keeps working if AMI naming changes again |
| `iam` | EC2 instance role + profile, CloudWatch agent policy attached | No S3/other access by default — attach more policies to the role as your app needs grow |
| `s3` | Private, versioned, AES-256 encrypted bucket | Public access fully blocked; `prevent_destroy` set so `terraform destroy` won't silently delete it |
| `route53` | A records pointing at the instance's public IP | Only created if `domain_name` is set in `terraform.tfvars`; requires the domain to already be delegated to a Route53 hosted zone |

**⚠️ Security note:** `allowed_ssh_cidr` defaults to `0.0.0.0/0` (SSH open to the whole internet) so a first `terraform plan` works out of the box. **Before running `apply` on anything beyond a quick throwaway test, set it to your own IP** (e.g. `"203.0.113.5/32"`) in `terraform.tfvars`.

---

## 8. Roadmap

### Phase 1 — MVP (real, runnable, not a demo)
Goal: an engineer can install MasterOps via `apt` and get a working, deployable skeleton for one real stack combination.

- [x] `masterops` CLI skeleton (`new`, `add`, `start`, `doctor`)
- [x] Debian packaging + private APT repo, installable end-to-end
- [x] CI/CD: Buildkite pipeline that builds and publishes the `.deb` on every push
- [x] Terraform: VPC, EC2, IAM, S3, and optional Route53 modules, wired through a single `main.tf`/`variables.tf`
- [x] Docker stack (base, non-root, multi-stage)
- [x] Nginx native server install, interactive domain + SSL setup
- [x] One full preset working end-to-end: **Laravel + PostgreSQL + React**
- [x] `masterops doctor` (RAM, ports, Docker version checks)
- [ ] Full idempotency testing on every script

### Phase 2 — V1 (full package, refactor from MVP learnings)
- [x] MySQL stack (`laravel-mysql` preset, container + native install, DB vars decoupled from backend)
- [ ] Python3 backend stack
- [ ] Kubernetes + Helm chart structure
- [ ] Cron job templates
- [ ] Supervisor job templates
- [ ] Security check bash scripts
- [ ] Daily S3 backup job
- [ ] Health monitoring + alerts (email / Telegram)
- [ ] `masterops diff` (drift detection)
- [ ] Unified secrets layer (`.env.vault`)
- [ ] `masterops.yaml` versioning + `masterops upgrade`
- [ ] GitHub Actions templates per stack

---

## 9. Notes
Copyright (c) 2026 Mohamed Tarek - Nexus Smart Solution. All rights reserved. See [LICENSE](./LICENSE).
- MVP is scoped to be genuinely usable on a real project, not a proof of concept — it should be dogfooded on an actual client project as soon as it lands.
- V1 is treated as a refactor pass informed by real MVP usage, not a from-scratch rebuild.
- Every module must remain independently testable and independently versioned.
