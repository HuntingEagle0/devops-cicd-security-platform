# Container Validation Policy
# Enforces image version tagging and prevents privileged container execution

package container

import rego.v1

# DENY: Container images must have explicit version tags (no 'latest')
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' uses image '%s' — the ':latest' tag is not allowed. Use a specific version tag.", [container.name, container.image])
}

# DENY: Container images must have a version tag (not untagged)
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not contains(container.image, ":")
    msg := sprintf("Container '%s' uses image '%s' without a version tag. All images must be explicitly tagged.", [container.name, container.image])
}

# DENY: Privileged containers are not allowed
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' must not run in privileged mode", [container.name])
}

# DENY: Container must not mount Docker socket
deny contains msg if {
    input.kind == "Deployment"
    some volume in input.spec.template.spec.volumes
    volume.hostPath.path == "/var/run/docker.sock"
    msg := "Mounting Docker socket (/var/run/docker.sock) is not allowed"
}

# DENY: CPU limits must be set and reasonable
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' must have CPU limits defined", [container.name])
}

# DENY: Memory limits must be set and reasonable
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.limits.memory
    msg := sprintf("Container '%s' must have memory limits defined", [container.name])
}

# DENY: Containers must not use capabilities like NET_ADMIN, SYS_ADMIN
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    some cap in container.securityContext.capabilities.add
    cap in {"NET_ADMIN", "SYS_ADMIN", "ALL"}
    msg := sprintf("Container '%s' must not add dangerous capability '%s'", [container.name, cap])
}

# WARN: Images should be from a trusted registry
warn contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not startswith(container.image, "gcr.io/")
    not startswith(container.image, "docker.io/")
    not startswith(container.image, "ghcr.io/")
    not startswith(container.image, "registry.example.com/")
    msg := sprintf("Container '%s' uses image '%s' from an untrusted registry", [container.name, container.image])
}
