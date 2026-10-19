# Persephone Liquid API Server Helm Chart

This Helm chart deploys the Persephone Liquid API Server, which implements the [Liquid API](https://github.com/sapcc/go-api-declarations/tree/master/liquid) interface for managing Gardener shoot cluster quotas via Limes.

## Overview

The liquid-apiserver runs in each OpenStack region and provides:
- Quota management for Gardener shoot clusters via the Liquid API
- Direct validation of Keystone tokens from incoming Limes requests (no application credentials needed)
- Access to the Virtual Garden API for managing ResourceQuotas in shoot namespaces

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Virtual Garden Cluster                    │
│  - Shoot namespaces                                          │
│  - ResourceQuota objects (shoot cluster quotas)              │
│  - RBAC for liquid-apiserver                                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ OIDC Auth (projected SA token)
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
┌───────▼───────────┐              ┌─────────▼──────────┐
│  Region: eu-de-1  │              │  Region: ap-au-1   │
│  Namespace:       │              │  Namespace:        │
│  persephone       │              │  persephone        │
│                   │              │                    │
│  ┌─────────────┐  │              │  ┌─────────────┐   │
│  │ Canary      │  │              │  │ Canary      │   │
│  │ liquid-api  │  │              │  │ liquid-api  │   │
│  └─────────────┘  │              │  └─────────────┘   │
│  ┌─────────────┐  │              │  ┌─────────────┐   │
│  │ Prod        │  │              │  │ Prod        │   │
│  │ liquid-api  │  │              │  │ liquid-api  │   │
│  └──────┬──────┘  │              │  └──────┬──────┘   │
│         │ OS Auth │              │         │ OS Auth  │
│         ▼         │              │         ▼          │
│  ┌──────────────┐ │              │  ┌──────────────┐  │
│  │  Keystone    │ │              │  │  Keystone    │  │
│  └──────────────┘ │              │  └──────────────┘  │
└───────────────────┘              └────────────────────┘
```

### Key Architecture Points

- **One namespace per region**: All deployments use the `persephone` namespace
- **Two installations per region**: Canary and prod coexist in the same namespace
- **Unique release names**: Resources are isolated by Helm release name (e.g., `liquid-canary`, `liquid-prod`)
- **One OIDC issuer per region**: Shared by both canary and prod installations
- **Multiple installations supported**: Chart can be installed multiple times in the same namespace

## Deployment Model

In each regional Kubernetes cluster (e.g., eu-de-1):

```bash
# Canary installation
helm install liquid-canary persephone-liquid-apiserver \
  --namespace persephone \
  --set landscape=canary \
  --set region=eu-de-1 \
  ...

# Prod installation
helm install liquid-prod persephone-liquid-apiserver \
  --namespace persephone \
  --set landscape=prod \
  --set region=eu-de-1 \
  ...
```

Both installations coexist in the same namespace with unique resource names:
- `liquid-canary-persephone-liquid-apiserver` (Deployment, Service, etc.)
- `liquid-prod-persephone-liquid-apiserver` (Deployment, Service, etc.)

## Prerequisites

1. **Regional Kubernetes Clusters**: One cluster per OpenStack region
2. **Virtual Garden OIDC Configuration**: One issuer per region (see RBAC setup below)
3. **RBAC in Virtual Garden**: ClusterRole and ClusterRoleBinding (see RBAC setup below)

## Installation

### 1. Configure Virtual Garden OIDC

Add ONE OIDC issuer per region to the Virtual Garden's AuthenticationConfiguration:

```yaml
# In cc-gardener.yaml (both canary and prod Virtual Gardens)
garden:
  virtualCluster:
    authenticationConfig:
      jwt:
        - issuer:
            url: <regional-cluster-api-url>
            audiences:
              - persephone-liquid
          claimMappings:
            username:
              claim: "sub"
              prefix: "liquid-apiserver:"
            groups:
              expression: 'claims["kubernetes.io"]["serviceaccount"]["groups"] + ["persephone:liquid-apiserver"]'
        # ... repeat for all 15 regions
```

**Important**: 
- Use ONE issuer per region (15 total), NOT per landscape
- The issuer URL is the regional Kubernetes cluster's API server
- Same issuer configuration in both canary and prod Virtual Gardens

### 2. Deploy RBAC to Virtual Garden

The `rbac-virtual-garden.yaml` file contains RBAC resources that must be deployed to the Virtual Garden cluster:

```bash
# Apply to canary Virtual Garden
kubectl apply -f rbac-virtual-garden.yaml \
  --context virtual-garden-canary

# Apply to prod Virtual Garden
kubectl apply -f rbac-virtual-garden.yaml \
  --context virtual-garden-prod
```

This creates:
- ClusterRole: `persephone-liquid-apiserver` (manage ResourceQuotas)
- ClusterRoleBinding: Grants permissions to service accounts from all regional installations

### 3. Deploy to Regional Clusters

Deploy both canary and prod to each regional cluster in the `persephone` namespace:

```bash
# Set common variables
REGION=eu-de-1
NAMESPACE=persephone

# Deploy canary
helm install liquid-canary . \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set region=${REGION} \
  --set landscape=canary \
  --set virtualGarden.apiServerURL=https://api.garden.canary.k8s.ondemand.com \
  --set openstack.authURL=https://identity-3.${REGION}.cloud.sap/v3

# Deploy prod
helm install liquid-prod . \
  --namespace ${NAMESPACE} \
  --set region=${REGION} \
  --set landscape=prod \
  --set virtualGarden.apiServerURL=https://api.garden.live.k8s.ondemand.com \
  --set openstack.authURL=https://identity-3.${REGION}.cloud.sap/v3
```

**Note**: Landscape-specific values files with all regions configured are maintained in the `cc/kube-secrets` repository.

## Configuration

### Key Values

| Parameter | Description | Required |
|-----------|-------------|----------|
| `region` | OpenStack region name (e.g., eu-de-1) | Yes |
| `landscape` | Landscape name (canary or prod) | Yes |
| `virtualGarden.apiServerURL` | Virtual Garden API URL | Yes |
| `virtualGarden.oidc.audience` | Token audience (default: persephone-liquid) | Yes |
| `openstack.authURL` | Keystone auth URL for direct token validation | Yes |

### Default Values

- `replicaCount`: 2
- `resources.requests`: 100m CPU, 128Mi memory
- `resources.limits`: 256Mi memory
- `networkPolicy.enabled`: false
- `autoscaling.enabled`: false

## Verification

### Test API Access

```bash
# Port-forward to the canary service
kubectl port-forward -n persephone svc/liquid-canary-persephone-liquid-apiserver 8080:80

# Get a Keystone token (use your existing authentication method)
# The liquid-apiserver will validate the token directly with Keystone
TOKEN="your-keystone-token"

# Test the info endpoint
curl -s -H "X-Auth-Token: $TOKEN" http://localhost:8080/v1/info | jq .
```

### Check Virtual Garden Access

```bash
# Verify canary service account can access Virtual Garden
kubectl exec -n persephone deployment/liquid-canary-persephone-liquid-apiserver -- \
  sh -c 'curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://api.garden.canary.k8s.ondemand.com/api/v1/namespaces'

# Expected: JSON response with namespaces (not 401/403)
```

## Troubleshooting

### Multiple Installations

This chart supports multiple installations in the same namespace. Each installation is isolated by the Helm release name:

```bash
# List all liquid-apiserver installations in persephone namespace
helm list -n persephone | grep liquid

# Check all deployments
kubectl get deployments -n persephone -l app=persephone,role=liquid-apiserver
```

### Authentication Errors

**Symptom**: 401 Unauthorized when accessing Virtual Garden API

**Solution**:
1. Verify OIDC issuer is configured in Virtual Garden
2. Check issuer URL matches the regional cluster's API server
3. Verify token audience: `persephone-liquid`
4. Check RBAC permissions in Virtual Garden

### Token Validation Errors

**Symptom**: 401 when Limes makes requests with X-Auth-Token

**Solution**:
1. Verify the provided Keystone token is valid
2. Check that OS_AUTH_URL is correctly set to the regional Keystone endpoint
3. Ensure the token has proper project/domain scope
4. Verify Keystone URL is correct for the region

## Maintenance

### Adding a New Region

1. Add OIDC issuer to Virtual Garden AuthenticationConfiguration
2. Update RBAC in Virtual Garden (if region list is hardcoded)
3. Deploy canary and prod installations to the new regional cluster

## Security

- **Non-root containers**: Runs as UID 1000
- **Read-only filesystem**: Root filesystem is read-only
- **Dropped capabilities**: All capabilities dropped
- **Least-privilege RBAC**: Only necessary permissions in Virtual Garden
- **Network policies**: Disabled by default (can be enabled)
- **Projected tokens**: Auto-rotating service account tokens (1-hour expiry)

## License

SPDX-FileCopyrightText: 2026 SAP SE or an SAP affiliate company

SPDX-License-Identifier: Apache-2.0
