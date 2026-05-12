#!/bin/bash
###############################################################################
# Linux Administration & User Management Setup Script
# Project: company-devops-platform
# Description: Automates user/group creation, permissions, directory structure,
#              configuration file management, process management, and archiving.
# Usage: sudo bash linux_setup.sh
###############################################################################

set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PROJECT_DIR="/opt/company-devops-platform"
BACKUP_DIR="${PROJECT_DIR}/backup"
LOG_FILE="${PROJECT_DIR}/reports/setup_${TIMESTAMP}.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo -e "\n${CYAN}======================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}======================================================================${NC}\n"
}

###############################################################################
# TASK 1 & 2: Create Project Directory Structure
###############################################################################
header "TASK 1 & 2: Creating Project Directory Structure"

mkdir -p "${PROJECT_DIR}"/{configs,deployments,policies,reports/sonarqube,backup,artifacts,logs}

log "Created project directory: ${PROJECT_DIR}"
log "Created subdirectories: configs, deployments, policies, reports, backup, artifacts, logs"

# Ensure log file directory exists and create log
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
log "Log file initialized at ${LOG_FILE}"

###############################################################################
# TASK 3: Create Users
###############################################################################
header "TASK 3: Creating Users"

for user in developer tester devopsadmin; do
    if id "$user" &>/dev/null; then
        warn "User '$user' already exists — skipping"
    else
        useradd -m -s /bin/bash "$user"
        echo "${user}:P@ssw0rd123!" | chpasswd
        log "Created user: $user"
    fi
done

###############################################################################
# TASK 4: Create Groups
###############################################################################
header "TASK 4: Creating Groups"

for group in developers operations; do
    if getent group "$group" &>/dev/null; then
        warn "Group '$group' already exists — skipping"
    else
        groupadd "$group"
        log "Created group: $group"
    fi
done

###############################################################################
# TASK 5: Add Users to Groups
###############################################################################
header "TASK 5: Assigning Users to Groups"

usermod -aG developers developer
usermod -aG developers tester
usermod -aG operations devopsadmin

log "Added 'developer' and 'tester' to 'developers' group"
log "Added 'devopsadmin' to 'operations' group"

# Verify group membership
log "Group memberships:"
getent group developers | tee -a "$LOG_FILE"
getent group operations | tee -a "$LOG_FILE"

###############################################################################
# TASK 6: Assign Permissions
###############################################################################
header "TASK 6: Configuring Permissions"

# Set ownership
chown -R devopsadmin:operations "${PROJECT_DIR}"

# developers group: read/write (no execute on files, r-x on dirs)
chgrp -R developers "${PROJECT_DIR}/configs"
chmod -R 775 "${PROJECT_DIR}/configs"

chgrp -R developers "${PROJECT_DIR}/deployments"
chmod -R 775 "${PROJECT_DIR}/deployments"

# devopsadmin: full administrative permissions
chmod -R 770 "${PROJECT_DIR}/policies"
chmod -R 770 "${PROJECT_DIR}/reports"

# Set ACL for developers group on project directories
if command -v setfacl &>/dev/null; then
    setfacl -R -m g:developers:rw "${PROJECT_DIR}/configs"
    setfacl -R -m g:developers:rw "${PROJECT_DIR}/deployments"
    setfacl -R -m g:operations:rwx "${PROJECT_DIR}"
    log "ACLs applied successfully"
else
    warn "setfacl not available — using standard Unix permissions only"
fi

log "Permissions configured:"
log "  - developers group: read/write on configs/ and deployments/"
log "  - devopsadmin (operations): full admin on entire project"

###############################################################################
# TASK 7: Create Configuration Files
###############################################################################
header "TASK 7: Creating Configuration Files"

# deployment.yaml
cat > "${PROJECT_DIR}/configs/deployment.yaml" << 'DEPLOYMENT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-platform-app
  namespace: production
  labels:
    app: devops-platform
    environment: production
    version: "1.0.0"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devops-platform
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: devops-platform
        version: "1.0.0"
    spec:
      containers:
        - name: devops-app
          image: devops-platform:1.0.0
          ports:
            - containerPort: 8080
              protocol: TCP
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: NODE_ENV
              value: "production"
            - name: LOG_LEVEL
              value: "info"
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: devops-platform-service
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: devops-platform
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
DEPLOYMENT_EOF
log "Created configs/deployment.yaml"

# pipeline.yaml
cat > "${PROJECT_DIR}/configs/pipeline.yaml" << 'PIPELINE_EOF'
# CI/CD Pipeline Configuration
pipeline:
  name: devops-cicd-security-platform
  version: "1.0.0"
  trigger:
    branches:
      - development
      - staging
      - production

stages:
  - name: source-checkout
    description: "Checkout source code from repository"
    timeout: 5m
    steps:
      - checkout: self
        fetchDepth: 0

  - name: build
    description: "Build application artifacts"
    timeout: 15m
    steps:
      - script: |
          echo "Installing dependencies..."
          npm ci --production=false
          echo "Building application..."
          npm run build
        displayName: "Build Application"

  - name: test
    description: "Run unit and integration tests"
    timeout: 20m
    steps:
      - script: |
          echo "Running unit tests..."
          npm run test:unit
          echo "Running integration tests..."
          npm run test:integration
        displayName: "Execute Tests"
      - publishTestResults:
          testResultsFormat: "JUnit"
          testResultsFiles: "**/test-results/*.xml"

  - name: security-validation
    description: "Run security scans and policy checks"
    timeout: 30m
    steps:
      - script: |
          echo "Running SonarQube analysis..."
          sonar-scanner
        displayName: "SonarQube Scan"
      - script: |
          echo "Running OPA policy validation..."
          conftest test configs/ --policy policies/
        displayName: "OPA Policy Check"

  - name: deployment
    description: "Deploy to target environment"
    timeout: 15m
    condition: succeeded()
    steps:
      - script: |
          echo "Deploying to environment..."
          kubectl apply -f configs/deployment.yaml
        displayName: "Deploy Application"

environment:
  variables:
    NODE_ENV: "production"
    LOG_LEVEL: "info"
    SONAR_HOST_URL: "http://localhost:9000"
  secrets:
    - SONAR_TOKEN
    - DOCKER_PASSWORD
    - KUBE_CONFIG

notifications:
  on_success:
    - email
    - slack
  on_failure:
    - email
    - slack
    - pagerduty

artifacts:
  paths:
    - "artifacts/"
    - "reports/"
  retention:
    days: 30
PIPELINE_EOF
log "Created configs/pipeline.yaml"

# security.conf
cat > "${PROJECT_DIR}/configs/security.conf" << 'SECURITY_EOF'
###############################################################################
# Security Configuration
# Project: company-devops-platform
# Last Updated: 2026-05-12
###############################################################################

[general]
# Enable strict security mode
strict_mode = true
# Enforce HTTPS connections
enforce_https = true
# Maximum login attempts before lockout
max_login_attempts = 5
# Lockout duration in minutes
lockout_duration = 30

[authentication]
# Password policy
min_password_length = 12
require_uppercase = true
require_lowercase = true
require_numbers = true
require_special_chars = true
password_expiry_days = 90
password_history_count = 5

# Multi-factor authentication
mfa_enabled = true
mfa_methods = totp,sms,email

# Session management
session_timeout = 1800
max_concurrent_sessions = 3
session_renewal = true

[authorization]
# Role-based access control
rbac_enabled = true
default_role = viewer
admin_group = operations
developer_group = developers

# API access control
api_rate_limit = 1000
api_rate_window = 3600
require_api_key = true

[network]
# Firewall rules
allowed_ports = 22,80,443,8080,9000
denied_networks = 0.0.0.0/8,10.0.0.0/8
trusted_proxies = 172.16.0.0/12

# TLS configuration
tls_version = 1.3
cipher_suites = TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256
hsts_enabled = true
hsts_max_age = 31536000

[logging]
# Audit logging
audit_log_enabled = true
audit_log_path = /var/log/devops-platform/audit.log
audit_log_rotation = daily
audit_log_retention = 365

# Security event logging
security_log_enabled = true
security_log_level = INFO
security_log_path = /var/log/devops-platform/security.log

[scanning]
# Vulnerability scanning
vuln_scan_enabled = true
vuln_scan_schedule = "0 2 * * *"
vuln_scan_severity_threshold = medium

# Container scanning
container_scan_enabled = true
container_scan_on_push = true
block_vulnerable_images = true

# Code scanning
code_scan_enabled = true
code_scan_tool = sonarqube
code_scan_quality_gate = strict
SECURITY_EOF
log "Created configs/security.conf"

###############################################################################
# TASK 8: Copy Configuration Files into Backup Directory
###############################################################################
header "TASK 8: Backing Up Configuration Files"

mkdir -p "${BACKUP_DIR}"
cp "${PROJECT_DIR}/configs/deployment.yaml" "${BACKUP_DIR}/"
cp "${PROJECT_DIR}/configs/pipeline.yaml"   "${BACKUP_DIR}/"
cp "${PROJECT_DIR}/configs/security.conf"   "${BACKUP_DIR}/"

log "Copied all configuration files to ${BACKUP_DIR}/"

###############################################################################
# TASK 9: Rename Copied Files Using Timestamps
###############################################################################
header "TASK 9: Renaming Backup Files with Timestamps"

mv "${BACKUP_DIR}/deployment.yaml" "${BACKUP_DIR}/deployment_${TIMESTAMP}.yaml"
mv "${BACKUP_DIR}/pipeline.yaml"   "${BACKUP_DIR}/pipeline_${TIMESTAMP}.yaml"
mv "${BACKUP_DIR}/security.conf"   "${BACKUP_DIR}/security_${TIMESTAMP}.conf"

log "Renamed backup files with timestamp: ${TIMESTAMP}"
ls -la "${BACKUP_DIR}/" | tee -a "$LOG_FILE"

###############################################################################
# TASK 10: Display Complete Project Structure
###############################################################################
header "TASK 10: Complete Project Structure"

if command -v tree &>/dev/null; then
    tree "${PROJECT_DIR}" | tee -a "$LOG_FILE"
else
    find "${PROJECT_DIR}" -print | sed -e "s;${PROJECT_DIR};.;g" | sort | tee -a "$LOG_FILE"
fi

###############################################################################
# TASK 11: Create a Background Process and Terminate It
###############################################################################
header "TASK 11: Background Process Management"

# Start a background process
sleep 300 &
BG_PID=$!
log "Started background process (sleep 300) with PID: ${BG_PID}"

# Verify the process is running
ps -p $BG_PID -o pid,ppid,cmd | tee -a "$LOG_FILE"
log "Background process is running"

# Terminate the background process
kill $BG_PID
wait $BG_PID 2>/dev/null || true
log "Terminated background process PID: ${BG_PID}"

# Verify it is terminated
if ps -p $BG_PID &>/dev/null; then
    error "Process ${BG_PID} is still running!"
else
    log "Confirmed: Process ${BG_PID} has been terminated successfully"
fi

###############################################################################
# TASK 12: Display Running Processes and Parent-Child Relationships
###############################################################################
header "TASK 12: Process Hierarchy & Parent-Child Relationships"

log "Current running processes (tree view):"
if command -v pstree &>/dev/null; then
    pstree -p | head -50 | tee -a "$LOG_FILE"
else
    ps -ef --forest | head -50 | tee -a "$LOG_FILE"
fi

log ""
log "Top 20 processes by CPU usage:"
ps aux --sort=-%cpu | head -20 | tee -a "$LOG_FILE"

log ""
log "Parent-child process relationship example:"
ps -eo pid,ppid,cmd --forest | head -30 | tee -a "$LOG_FILE"

###############################################################################
# TASK 13: Create Compressed Archive of the Entire Project Directory
###############################################################################
header "TASK 13: Creating Project Archive"

ARCHIVE_NAME="company-devops-platform_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="/tmp/${ARCHIVE_NAME}"

tar -czf "${ARCHIVE_PATH}" -C "$(dirname ${PROJECT_DIR})" "$(basename ${PROJECT_DIR})"

ARCHIVE_SIZE=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
log "Created compressed archive: ${ARCHIVE_PATH}"
log "Archive size: ${ARCHIVE_SIZE}"

# Copy archive into artifacts
cp "${ARCHIVE_PATH}" "${PROJECT_DIR}/artifacts/"
log "Archive also stored at: ${PROJECT_DIR}/artifacts/${ARCHIVE_NAME}"

###############################################################################
# SUMMARY
###############################################################################
header "SETUP COMPLETE"

echo -e "${GREEN}✅ All Linux administration tasks completed successfully!${NC}"
echo ""
echo "Summary:"
echo "  📁 Project Directory : ${PROJECT_DIR}"
echo "  👤 Users Created     : developer, tester, devopsadmin"
echo "  👥 Groups Created    : developers, operations"
echo "  🔐 Permissions       : Configured with ACLs"
echo "  📄 Config Files      : deployment.yaml, pipeline.yaml, security.conf"
echo "  💾 Backup Directory  : ${BACKUP_DIR}"
echo "  📦 Archive           : ${ARCHIVE_PATH}"
echo "  📝 Log File          : ${LOG_FILE}"
echo ""
log "Setup completed at $(date)"
