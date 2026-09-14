# MasterOps

**A DevOps project bootstrap package.** One command turns a fresh server or a new project into a fully provisioned, production-ready environment — the way `composer create-project laravel/laravel` gives you a working Laravel skeleton, MasterOps gives a DevOps engineer a working infrastructure skeleton.

```bash
sudo apt update && sudo apt install masterops
masterops new my-project --preset=laravel-postgres-react
```

No engineer should start a new project or join a new server by writing VPC code, Nginx configs, or CI pipelines from scratch again. MasterOps installs the scaffolding. The engineer only edits variables and decides what actually runs.

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
6. **One `main.tf` to edit.** All Terraform modules are pre-wired; the engineer only ever touches `variables.tf` and `terraform.tfvars`.

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
│   │   ├── deploy.sh                 # masterops deploy --env=production
│   │   ├── doctor.sh                 # pre-flight server checks
│   │   ├── diff.sh                   # drift detection
│   │   ├── backup.sh                 # manual/triggered backup run
│   │   └── upgrade.sh                # bump stack versions per project
│   └── lib/                          # shared helpers: logging, prompts, validation
│
├── terraform/
│   ├── main.tf                       # the ONLY file engineers wire modules in
│   ├── variables.tf                  # the ONLY file engineers edit day-to-day
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/
│       ├── subnets/
│       ├── security-groups/
│       ├── iam/
│       ├── ec2/
│       └── alb/
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
│   ├── debian/                       # .deb control files / fpm config
│   └── repo/                         # APT repo publishing scripts
│
└── masterops.yaml                    # generated per-project: records stack versions in use
```

---

## 4. Full module list

| Category | Modules |
|---|---|
| Infra (Terraform) | VPC, Subnets, Security Groups, IAM, EC2, ALB |
| Scripting | Bash helper library shared across all stacks |
| Databases | PostgreSQL, MySQL |
| Backend | Laravel (PHP), Python3 |
| Frontend | ReactJS |
| Containers | Docker, Kubernetes, Helm (standard chart structure) |
| Web server | Nginx (native install on the server, not container-only) |
| Process management | Cron jobs, Supervisor jobs |
| Security | Bash-based security check scripts |
| Backup | Daily backup job to S3 |
| Monitoring / Alerts | Server health checks pushed to email / Telegram |
| Diagnostics | `masterops doctor` (pre-install server readiness check) |
| Consistency | `masterops diff` (drift detector: local config vs. live server) |
| Secrets | Unified `.env.vault` layer (age/sops-encrypted), read by every stack |
| Versioning | `masterops.yaml` per-project stack version lock + `masterops upgrade` |

---

## 5. Command reference (target)

```bash
masterops new <project> --preset=<preset-name>   # scaffold a new project locally
masterops add <stack>                             # add a stack to an existing project
masterops start <service>                         # explicitly start a service/container
masterops doctor                                  # check server readiness before install
masterops diff                                    # show drift between local config and server
masterops deploy --env=<environment>               # provision + deploy to a server
masterops backup run                              # trigger an on-demand backup
masterops upgrade                                 # bump a project's stacks to newer versions
```

---

## 6. Distribution

MasterOps ships as a real Debian package through a private APT repository (via Packagecloud/Cloudsmith initially, or self-hosted with `aptly`/`reprepro` later), so installation on any server is:

```bash
curl -s https://packagecloud.io/install/repositories/<you>/masterops/script.deb.sh | sudo bash
sudo apt install masterops
```

---

## 7. Roadmap

### Phase 1 — MVP (real, runnable, not a demo)
Goal: an engineer can install MasterOps via `apt` and get a working, deployable skeleton for one real stack combination.

- [ ] `masterops` CLI skeleton (`new`, `add`, `start`, `doctor`)
- [ ] Debian packaging + private APT repo, installable end-to-end
- [ ] Terraform: VPC, Subnets, Security Groups, IAM, EC2, ALB modules + unified `main.tf`/`variables.tf`
- [ ] Docker stack (base, non-root, multi-stage)
- [ ] Nginx native server install
- [ ] One full preset working end-to-end: **Laravel + PostgreSQL + React**
- [ ] `masterops doctor` (RAM, ports, Docker version checks)
- [ ] Basic idempotency testing on every script

### Phase 2 — V1 (full package, refactor from MVP learnings)
- [ ] MySQL stack
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

## 8. Notes
All rights belong to @motarekdevops
- MVP is scoped to be genuinely usable on a real project, not a proof of concept — it should be dogfooded on an actual client project as soon as it lands.
- V1 is treated as a refactor pass informed by real MVP usage, not a from-scratch rebuild.
- Every module must remain independently testable and independently versioned.
