# Security Validation Policy
# Prevents insecure deployments and restricts root user execution

package security

import rego.v1

# DENY: Containers must NOT run as root
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    container.securityContext.runAsUser == 0
    msg := sprintf("Container '%s' must not run as root (UID 0)", [container.name])
}

# DENY: runAsNonRoot must be set to true
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container '%s' must set securityContext.runAsNonRoot to true", [container.name])
}

# DENY: Privilege escalation must be disabled
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    container.securityContext.allowPrivilegeEscalation == true
    msg := sprintf("Container '%s' must not allow privilege escalation", [container.name])
}

# DENY: Root filesystem should be read-only
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.securityContext.readOnlyRootFilesystem
    msg := sprintf("Container '%s' should have a read-only root filesystem", [container.name])
}

# DENY: Host network must not be used
deny contains msg if {
    input.kind == "Deployment"
    input.spec.template.spec.hostNetwork == true
    msg := "Deployment must not use host network"
}

# DENY: Host PID namespace must not be shared
deny contains msg if {
    input.kind == "Deployment"
    input.spec.template.spec.hostPID == true
    msg := "Deployment must not share host PID namespace"
}

# WARN: Sensitive environment variables should use secrets
warn contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    some env_var in container.env
    contains(lower(env_var.name), "password")
    env_var.value
    msg := sprintf("Container '%s': env var '%s' contains sensitive data — use a Secret reference instead", [container.name, env_var.name])
}

# WARN: Sensitive environment variables should use secrets
warn contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    some env_var in container.env
    contains(lower(env_var.name), "token")
    env_var.value
    msg := sprintf("Container '%s': env var '%s' contains sensitive data — use a Secret reference instead", [container.name, env_var.name])
}
