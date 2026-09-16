# MasterOps 🚀

**MasterOps** is a production-grade DevOps bootstrap CLI designed to eliminate the manual toil of setting up application environments on Linux servers. It transforms the "Day 1" experience from a series of manual steps into a single, idempotent command.

Instead of just creating skeletons, MasterOps provisions **real** environments: it detects the required runtime, installs the correct SDK/version, restores dependencies, builds the application, configures systemd services, and sets up Nginx reverse proxies.

## 🎯 Why MasterOps?

Setting up a production server typically involves dozens of repetitive tasks: installing runtimes, configuring databases, tweaking Nginx, and setting up systemd. MasterOps automates this entire chain, ensuring that every environment is consistent, secure, and runnable from the very first second.

**Key Benefits:**
- **Zero-Configuration Start**: Go from a blank server to a running app in minutes.
- **Framework Agnostic**: First-class support for .NET, Spring Boot, Laravel, Django, and Go.
- **Infrastructure as Code**: Uses Ansible for idempotent provisioning and Terraform for AWS.
- **Production Ready**: Implements professional systemd management and Nginx vhosts.

---

## 📦 Installation

### 1. Debian Package (Recommended)
The fastest way to install MasterOps is via the official `.deb` package:
```bash
sudo dpkg -i masterops_0.1.15_amd64.deb
```

### 2. Source Installation
For developers wanting to contribute or customize:
```bash
git clone https://github.com/nexus/masterops.git
cd masterops
sudo ln -s $(pwd)/bin/masterops /usr/local/bin/masterops
export MASTEROPS_HOME=$(pwd)
```

---

## 🛠️ Command Reference

| Command | Description | Example |
| :--- | :--- | :--- |
| `start` | **The Day 1 Wizard**. Provisions a full project environment including runtime, DB, and Nginx. | `masterops start my-app` |
| `diff` | **Drift Detection**. Compares actual system state against the desired configuration. | `masterops diff my-app` |
| `upgrade` | **Config Versioning**. Migrates project state to the latest configuration version. | `masterops upgrade my-app` |
| `status` | **Health Check**. Inspects project health, runtime versions, and service status. | `masterops status` |
| `run` | **Service Control**. Manages specific services within an existing project. | `masterops run backend` |
| `cleanup` | **Wipe Project**. Removes all files and state for a fresh start. | `masterops cleanup my-app` |
| `audit` | **Security Audit**. Checks for open ports, root-run services, and unsafe permissions. | `masterops audit` |
| `backup` | **S3 Backup**. Triggers an immediate encrypted backup of databases and configs. | `masterops backup` |
| `vault` | **Secret Management**. Manages AES-256 encrypted project secrets. | `masterops vault set KEY=VAL` |
| `terraform` | **Cloud Infra**. Provisions AWS VPC, EC2, S3, and IAM automatically. | `masterops terraform --start` |
| `nginx` | **Web Server**. Manages global Nginx installation and configuration. | `masterops nginx --start` |
| `new` | **Project Scaffold**. Creates a basic project structure. | `masterops new my-app` |
| `version` | **Version Check**. Displays the current MasterOps version. | `masterops version` |

---

## 🚀 How to Use It

### The Bootstrapping Workflow
The primary entry point for any new project is the `start` command.

1. **Initiate**: Run `masterops start <project_name>`.
2. **Configure**: The interactive wizard will ask you to select:
   - **Backend Framework**: (.NET, Spring Boot, Laravel, Django, Go)
   - **Frontend Framework**: (React, Vue, Next.js, etc.)
   - **Database Engine**: (Postgres, MySQL, MariaDB, Redis)
   - **Installation Mode**: (Native or Containerized)
   - **Domain Name**: (e.g., `app.example.com`)
3. **Automated Provisioning**: MasterOps will then:
   - Create the project directory under `/var/www/<project_name>`.
   - Install the exact runtime version needed.
   - Scaffold a runnable "Day 1" application if the directory is empty.
   - Provision the database and generate a unique, secure password.
   - Configure the systemd service and Nginx vhost.
4. **Verify**: Run `masterops status` to confirm the application is `Running` and `Health: OK`.

### Managing Drift
As servers evolve, manual changes often introduce "drift." Use `masterops diff <project>` to detect if the actual installed framework or database differs from the desired state recorded in `masterops.yaml`.

### Versioning and Upgrades
When the MasterOps engine is updated with new features or security patches, use `masterops upgrade <project>` to migrate your existing project state to the current version without losing data.

---

## 🏗️ Architecture

MasterOps is built on a layered architecture for maximum reliability:
- **CLI Layer**: A unified shell interface providing a consistent UX.
- **State Layer**: YAML-based tracking (`.masterops/state.yaml`) ensuring every operation is idempotent.
- **Provisioning Layer**: A modular Ansible library that handles the heavy lifting of OS-level configuration.
- **Security Layer**: Dynamic secret generation using `openssl` to eliminate hardcoded credentials.

## ⏱️ Value Proposition

| Task | Manual Process | MasterOps | Savings |
| :--- | :--- | :--- | :--- |
| OS Hardening | 60 min | 2 min | ~58 min |
| Runtime Setup | 15 min | 1 min | ~14 min |
| Framework Build | 30 min | 2 min | ~28 min |
| Nginx & SSL | 30 min | 1 min | ~29 min |
| CI/CD Pipeline | 120 min | 5 min | ~115 min |
| **Total** | **~4.2 Hours** | **~11 Minutes** | **~4 Hours** |
