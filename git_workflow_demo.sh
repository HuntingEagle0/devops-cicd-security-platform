#!/bin/bash
###############################################################################
# Git & GitHub Workflow Demo Script
# Usage: bash git_workflow_demo.sh
###############################################################################
set -euo pipefail

REPO_NAME="devops-cicd-security-platform"
GITHUB_USER="HuntingEagle0"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

step() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${GREEN}▶ $1${NC}\n"; }

# TASK 2: Init Git
step "Initialize Git"
cd "$(dirname "$0")"
git init
git remote add origin "${REMOTE_URL}" 2>/dev/null || git remote set-url origin "${REMOTE_URL}"

# Commit 1: Linux Setup
step "Commit 1: Linux Setup"
git add linux_setup.sh configs/ || true
git commit -m "feat: add Linux setup script and configs"

# TASK 3: Create Branches
step "Create Branches"
git branch development; git branch staging; git branch production
git branch -a

# Commit 2: Git Workflow
step "Commit 2: Git Workflow"
git checkout development
git add git_workflow_demo.sh || true
git commit -m "feat: add Git workflow demo script"

# Commit 3: CI/CD
step "Commit 3: CI/CD"
git add .github/ || true
git commit -m "feat: add CI/CD pipeline configs" || true

# Commit 4: SonarQube
step "Commit 4: SonarQube"
git add sonar-project.properties reports/ || true
git commit -m "feat: integrate SonarQube scanning" || true

# Commit 5: OPA
step "Commit 5: OPA Policies"
git add policies/ || true
git commit -m "feat: add OPA security policies" || true

# TASK 4: Push all branches
step "Push All Branches"
git checkout main 2>/dev/null || git checkout master
git merge development --no-edit || true
git push -u origin main 2>/dev/null || git push -u origin master
git push -u origin development; git push -u origin staging; git push -u origin production

# TASK 6: Merge Conflict
step "Simulate & Resolve Merge Conflict"
git checkout development
echo -e "ENV=development\nDEBUG=true" > environment.conf
git add environment.conf && git commit -m "feat: dev environment config"

git checkout staging
echo -e "ENV=staging\nDEBUG=false" > environment.conf
git add environment.conf && git commit -m "feat: staging environment config"

git merge development || true
echo -e "ENV=staging\nDEBUG=false\nLOG_LEVEL=info" > environment.conf
git add environment.conf && git commit -m "fix: resolve merge conflict"

# TASK 7a: Stash
step "Stash Demo"
echo "wip" > wip.txt; git add wip.txt
git stash save "WIP changes"; git stash list; git stash pop; rm -f wip.txt

# TASK 7b: Cherry-pick
step "Cherry-pick Demo"
git checkout development
echo "cherry" > cherry.txt; git add cherry.txt; git commit -m "feat: cherry-pick feature"
CHERRY=$(git rev-parse HEAD)
git checkout staging; git cherry-pick "${CHERRY}"

# TASK 7c: Rebase
step "Rebase Demo"
git checkout development
echo "rebase" > rebase.txt; git add rebase.txt; git commit -m "feat: rebase demo"
git checkout staging; git rebase development

# TASK 7d: Revert
step "Revert Demo"
git checkout development
echo "bad" > bad.txt; git add bad.txt; git commit -m "feat: bad feature"
git revert HEAD --no-edit

# TASK 7e: Reset
step "Reset Demo"
echo "reset" > reset.txt; git add reset.txt; git commit -m "feat: reset demo"
git reset --soft HEAD~1; git reset HEAD reset.txt; rm -f reset.txt

# TASK 8: File Recovery
step "File Recovery"
git checkout development
echo "important" > important.txt; git add important.txt; git commit -m "docs: add important file"
rm important.txt; git add important.txt; git commit -m "chore: accidental delete"
git checkout HEAD~1 -- important.txt; git add important.txt; git commit -m "fix: recover file"

# TASK 9: Graphical History
step "Graphical Commit History"
git log --all --graph --oneline --decorate -20

echo -e "\n${GREEN}✅ All Git workflow tasks completed!${NC}"
