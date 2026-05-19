# Equivalence Verification Findings

## Summary

The kustomize POC successfully produces functionally equivalent resources to the current
Helm-based `metal-operator-remote` chart. The rt-eu-de-1 overlay output matches the live
cluster deployment exactly.

**Verdict:** The approach works. Differences are cosmetic (naming, labels) and can be
addressed with additional patches if strict name-equivalence is required.

## Remote CRDs/RBAC

**Resource count:**
- Kustomize: 72 resources (16 CRDs, 52 ClusterRoles, 3 ClusterRoleBindings, 1 ServiceAccount)
- Helm (current): 72 resources (same breakdown)

**Differences:**

| Aspect | Kustomize | Helm (current) | Impact |
|--------|-----------|----------------|--------|
| Core RBAC name prefix | `manager-role`, `leader-election-role` | `metal-operator-manager-role`, `metal-operator-leader-election-role` | Naming only. Can add per-resource name patches or accept new names. |
| Per-CRD roles | `biossettings-admin-role` (no prefix) | `biossettings-admin-role` (no prefix) | **Identical** |
| ServiceAccount name | `controller-manager` | `metal-operator-controller-manager` | Naming difference |
| CRD names | All 16 CRDs | All 16 CRDs | **Identical** |

**Recommendation:** Accept upstream names. The `metal-operator-` prefix was a Helm artifact, not a requirement.

## Webhooks

**Match:** Webhook names and URLs are **identical** to current `webhooks.yaml`.

**Differences:**

| Aspect | Kustomize | Helm (current) | Impact |
|--------|-----------|----------------|--------|
| Resource name | `validating-webhook-configuration` | `metal-operator-validating-webhook-configuration` | Naming only |
| Labels | kustomize-managed | Helm-managed (chart version, etc.) | Cosmetic |

## Host Deployment (rt-eu-de-1)

**Matches live cluster exactly:**
- ✓ Container image: `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metal-operator-controller-manager:sha-4854c23`
- ✓ Args: 8 args matching live (`--enforce-first-boot`, `--enforce-power-off`, correct probe images)
- ✓ Env vars: `ENABLE_WEBHOOKS=false`, `KUBERNETES_CLUSTER_DOMAIN`, `KUBERNETES_SERVICE_HOST` (no stale `KUBECONFIG` var)
- ✓ Volume mounts: only `macdb` + `remote-kubeconfig` (no webhook-certs, no remote-serviceaccount)
- ✓ Volumes: `macdb` (secret) + `remote-kubeconfig` (secret with token/ca.crt items)
- ✓ initContainers: empty (webhook-injector removed)
- ✓ Strategy: Recreate
- ✓ Pod labels: all 6 Gardener networking labels
- ✓ Resource limits: cpu 5, memory 5Gi / requests cpu 300m, memory 50Mi
- ✓ serviceAccountName: default

**Kustomize technique:** Overlays that need to fully replace arrays (volumes, volumeMounts, env)
must use JSON patch (`op: replace` on the full array path) instead of strategic merge, which
merges arrays by element `name` and causes duplicates.

## Other Host Resources (rt-eu-de-1)

| Resource | Status | Value |
|----------|--------|-------|
| Ingress host | ✓ | `metal-operator-remote.runtime.eu-de-1.cloud.sap` |
| Service | ✓ | `metal-operator-metal-registry-service` port 10000 |
| NetworkPolicy | ✓ | Correct pod selector and ingress rules |
| Secrets | ✓ | macdb, metal-operator-remote-kubeconfig, metal-token-rotate-kubeconfig |
| ConfigMap | ✓ | remote-kubeconfig with correct apiserver URL |
| Webhook resources | ✓ removed | No webhook-service, no webhook-injector RBAC, no webhook-config |

## Remote Custom Resources (rt-eu-de-1)

| Resource | Status | Value |
|----------|--------|-------|
| Namespace | ✓ | `metal-servers` |
| OIDC IAS admin | ✓ | `CC_IAS_CONTROLPLANE_PROD_ADMIN` (via prod Component) |
| OIDC IAS viewer/editor | ✓ | `CC_IAS_CONTROLPLANE_PROD_DEVELOPER` (via prod Component) |
| metal-token-rotate | ✓ | SA + ClusterRole + ClusterRoleBinding + Role + RoleBinding |
| metal-api-viewer | ✓ | ClusterRole with correct rules |
| webhook-injector remote RBAC | ✓ | ClusterRole + ClusterRoleBinding |
| Base without component | ✓ | Shows `MUST_BE_SET_IN_OVERLAY` (prevents silent misconfiguration) |

## Top-Level Overlay

`kubectl apply -k overlays/rt-eu-de-1/` produces 167 resources in a single output:
- 1 Deployment, 1 Service, 1 Ingress, 1 NetworkPolicy, 1 ConfigMap, 3 Secrets
- 73 ManagedResources + 76 Secrets (remote upstream)
- 13 remote custom resources (Namespace, RBAC)

## ManagedResource Format

The `wrap-managedresources.sh` script produces ManagedResource+Secret pairs with the same
structure as the Helm template (`templates/managedresource.yaml`):
- ✓ Same naming convention: `mr-<kind-prefix>-<name>`
- ✓ Same Secret format: `data.objects.yaml` with base64-encoded resource
- ✓ Each resource gets its own ManagedResource (1:1 mapping)

## Blockers Identified

**None.** All differences are cosmetic (naming, labels) and don't affect functionality.

## Flux Compatibility

- ✓ No custom KRM function plugins used
- ✓ `kustomize build` succeeds on all overlay paths without external tools
- ✓ Pre-rendered files are valid static YAML
- ✓ Remote git resources in kustomization.yaml are supported by Flux kustomize-controller

## Recommendations

1. **Accept upstream names** for RBAC resources instead of adding `metal-operator-` prefix.
   This is simpler and follows upstream conventions. Document the name change for migration.

2. **Webhook ConfigMap name** should be patched to `metal-operator-validating-webhook-configuration`
   if webhook-injector expects that exact name, or update webhook-injector config to use the
   upstream name.

3. **Consider automated `make regen`** via GitHub Action on PRs that modify upstream refs
   (future enhancement, not a blocker).

4. **JSON patch for array replacement** — document in README that overlays overriding
   volumes/volumeMounts/env must use JSON patch (`op: replace`) not strategic merge to
   avoid array merging issues.
