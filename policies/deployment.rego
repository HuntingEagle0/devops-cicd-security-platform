# Deployment Validation Policy
# Ensures deployments follow security and operational best practices

package deployment

import rego.v1

# DENY: Deployment must have resource limits defined
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.limits
    msg := sprintf("Container '%s' must have resource limits defined", [container.name])
}

# DENY: Deployment must have resource requests defined
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.requests
    msg := sprintf("Container '%s' must have resource requests defined", [container.name])
}

# DENY: Deployment must have at least 2 replicas for high availability
deny contains msg if {
    input.kind == "Deployment"
    input.spec.replicas < 2
    msg := sprintf("Deployment '%s' must have at least 2 replicas, got %d", [input.metadata.name, input.spec.replicas])
}

# DENY: Deployment must have a liveness probe
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.livenessProbe
    msg := sprintf("Container '%s' must have a livenessProbe configured", [container.name])
}

# DENY: Deployment must have a readiness probe
deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.readinessProbe
    msg := sprintf("Container '%s' must have a readinessProbe configured", [container.name])
}

# DENY: Deployment must have labels
deny contains msg if {
    input.kind == "Deployment"
    not input.metadata.labels
    msg := sprintf("Deployment '%s' must have metadata labels", [input.metadata.name])
}

# DENY: Deployment must specify a namespace (not default)
deny contains msg if {
    input.kind == "Deployment"
    input.metadata.namespace == "default"
    msg := sprintf("Deployment '%s' must not use the 'default' namespace", [input.metadata.name])
}

# DENY: RollingUpdate strategy must be used
deny contains msg if {
    input.kind == "Deployment"
    input.spec.strategy.type != "RollingUpdate"
    msg := sprintf("Deployment '%s' must use RollingUpdate strategy", [input.metadata.name])
}
