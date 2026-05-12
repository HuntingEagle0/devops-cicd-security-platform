# DevOps CI/CD Security & Version Control Management System

[![Development Pipeline](https://img.shields.io/badge/CI%2FCD-Development%20Pipeline-success?style=for-the-badge&logo=githubactions)](https://github.com/YOUR_GITHUB_USERNAME/devops-cicd-security-platform/actions)
[![Production Pipeline](https://img.shields.io/badge/CI%2FCD-Production%20Pipeline-success?style=for-the-badge&logo=githubactions)](https://github.com/YOUR_GITHUB_USERNAME/devops-cicd-security-platform/actions)
[![SonarQube Quality Gate](https://img.shields.io/badge/SonarQube-Quality%20Gate%3A%20Passed-success?style=for-the-badge&logo=sonarqube)](https://sonarcloud.io)
[![OPA Validation](https://img.shields.io/badge/OPA-Policies%20Validated-success?style=for-the-badge&logo=openpolicyagent)](https://www.openpolicyagent.org/)

## 📖 Project Overview

This project implements a comprehensive DevOps workflow focusing on:
1. **Linux Administration & User Management**
2. **Git & GitHub Version Control Collaboration**
3. **CI/CD Automation (GitHub Actions)**
4. **SonarQube Code Quality Integration**
5. **Open Policy Agent (OPA) Security Policy Enforcement**

## 📂 Project Structure

```text
company-devops-platform/
├── .github/
│   └── workflows/
│       ├── dev-pipeline.yml        # CI/CD for development branch
│       └── prod-pipeline.yml       # CI/CD for production branch
├── configs/
│   ├── deployment.yaml             # Kubernetes deployment manifest
│   ├── pipeline.yaml               # Generic pipeline definition
│   └── security.conf               # Security standards configuration
├── policies/
│   ├── container.rego              # OPA: Image tagging & privilege limits
│   ├── deployment.rego             # OPA: Operational best practices
│   └── security.rego               # OPA: Root user restriction & host networks
├── reports/
│   ├── sonarqube/
│   │   └── scan-report.json        # Static analysis results
│   └── opa-validation-report.json  # Policy compliance results
├── logs/
│   └── deployment.log              # Automated deployment execution logs
├── linux_setup.sh                  # Automation script for Linux/OS Setup
├── git_workflow_demo.sh            # Automation script for Git tasks
└── sonar-project.properties        # SonarQube analysis configuration
```

## 🛠️ Phase 1: Linux Administration

The `linux_setup.sh` script automates the creation of the server environment:
- Creates users: `developer`, `tester`, `devopsadmin`
- Creates groups: `developers`, `operations`
- Configures directory permissions & ACLs.
- Automates configuration backups with timestamping.
- Manages background processes and system archives.

**Usage (on a Linux Server/WSL):**
```bash
sudo bash linux_setup.sh
```

## 🌿 Phase 2: Git & GitHub Branching Strategy

We follow a robust branching strategy to ensure code quality and deployment safety. Run `bash git_workflow_demo.sh` to simulate and view the entire workflow locally.

### Branching Model
- **`main` / `master`**: Source of truth. Reflects the currently released state.
- **`development`**: Integration branch. All feature branches merge here. Triggers the automated test and security scanning CI/CD pipeline.
- **`staging`**: Pre-production environment. Used for final QA testing before production deployment.
- **`production`**: Production deployment branch. Triggers the production CI/CD pipeline.

### Git Features Demonstrated
The `git_workflow_demo.sh` script actively demonstrates:
- Conflict resolution during merges.
- Temporary shelving of work (`git stash`).
- Moving specific commits (`git cherry-pick`).
- Linearizing history (`git rebase`).
- Undoing changes (`git revert` & `git reset`).
- Recovering accidentally deleted files.

## 🚀 Phase 3 & 4: CI/CD Pipeline & SonarQube

Implemented using **GitHub Actions**, the pipeline automatically triggers on pushes to specific branches.

### Development Pipeline Stages
1. **Source Checkout**: Fetches the latest code.
2. **Build**: Compiles artifacts.
3. **Test**: Executes Unit & Integration tests.
4. **Security Validation (SonarQube)**:
   - Scans YAML, shell scripts, and source code.
   - Generates reports for bugs, vulnerabilities, and code smells.
   - Validates against the Quality Gate (fails pipeline if not met).
5. **Deployment**: Deploys to the development Kubernetes cluster. Automatically rolls back if the deployment fails.

## 🛡️ Phase 5: Open Policy Agent (OPA)

Before any deployment manifest is applied, it is validated against OPA policies using `conftest`.
- **Deployment Validations**: Enforces resource limits, replicas, liveness/readiness probes, and proper namespaces.
- **Security Validations**: Prevents containers from running as `root`, disables privilege escalation, and enforces read-only file systems.
- **Container Validations**: Enforces specific image version tags (no `:latest`), prevents Docker socket mounting, and restricts dangerous capabilities (`NET_ADMIN`, `SYS_ADMIN`).

If a policy violation occurs, the pipeline fails, preventing insecure configurations from being deployed.

---
*Created as part of the DevOps CI/CD Security & Version Control Management System requirements.*
