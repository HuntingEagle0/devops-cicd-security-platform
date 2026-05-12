#!/bin/bash
###############################################################################
# OPA / Conftest Installation & Policy Validation Script
# Usage: bash validate_policies.sh
###############################################################################
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
REPORT_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  OPA Policy Validation - devops-cicd-security-platform${NC}"
echo -e "${CYAN}================================================================${NC}"

###########################################################################
# Install Conftest if not present
###########################################################################
if ! command -v conftest &>/dev/null; then
    echo -e "${YELLOW}Installing Conftest...${NC}"
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/arm64/')
    LATEST=$(curl -s https://api.github.com/repos/open-policy-agent/conftest/releases/latest \
              | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    wget -q "https://github.com/open-policy-agent/conftest/releases/download/v${LATEST}/conftest_${LATEST}_${OS}_${ARCH}.tar.gz" -O /tmp/conftest.tar.gz
    tar xzf /tmp/conftest.tar.gz -C /tmp
    sudo mv /tmp/conftest /usr/local/bin/conftest
    echo -e "${GREEN}Conftest ${LATEST} installed successfully${NC}"
fi

CONFTEST_VERSION=$(conftest --version)
echo -e "${GREEN}Using: ${CONFTEST_VERSION}${NC}"

mkdir -p "${REPORT_DIR}"

###########################################################################
# Validate all config files
###########################################################################
VIOLATIONS=0
TARGET_FILES=("configs/deployment.yaml" "deployments/staging.yaml" "deployments/production.yaml")

for FILE in "${TARGET_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo -e "${YELLOW}[SKIP] ${FILE} not found${NC}"
        continue
    fi

    echo -e "\n${CYAN}Validating: ${FILE}${NC}"

    # Run all three policy packages
    for PACKAGE in deployment security container; do
        echo -n "  Testing policy: ${PACKAGE}... "
        if conftest test "${FILE}" --policy "policies/${PACKAGE}.rego" --output json \
             >> "${REPORT_DIR}/opa-run-${TIMESTAMP}.json" 2>&1; then
            echo -e "${GREEN}PASS${NC}"
        else
            echo -e "${RED}FAIL${NC}"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    done
done

###########################################################################
# Final combined report
###########################################################################
echo ""
echo -e "${CYAN}================================================================${NC}"
if [ "$VIOLATIONS" -eq 0 ]; then
    echo -e "${GREEN}  ✅ ALL POLICIES PASSED — Deployment approved${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}  ❌ ${VIOLATIONS} POLICY VIOLATION(S) DETECTED — Deployment blocked${NC}"
    EXIT_CODE=1
fi
echo -e "${CYAN}================================================================${NC}"
echo "  Report saved: ${REPORT_DIR}/opa-run-${TIMESTAMP}.json"

exit $EXIT_CODE
