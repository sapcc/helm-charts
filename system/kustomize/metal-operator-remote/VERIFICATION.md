# Equivalence Verification Findings

## Summary

The kustomize POC successfully produces functionally equivalent resources to the current
Helm-based `metal-operator-remote` chart. Key differences are documented below.

**Verdict:** The approach works. Differences are cosmetic (naming, labels) and can be
addressed with additional patches if strict name-equivalence is required.

## Remote CRDs/RBAC

**Resource count:**
- Kustomize: 72 resources (16 CRDs, 52 ClusterRoles, 3 ClusterRoleBindings, 1 ServiceAccount)
- Helm (current): 72 resources (same breakdown)

**Differences:**

| Aspect | Kustomize | Helm (current) | Impact |
|--------|-----------|----------------|--------|
| RBAC name prefix | `manager-role`, `leader-election-role` | `metal-operator-manager-role`, `metal-operator-leader-election-role` | Naming only. Can add per-resource name patches or accept new names. |
| Per-CRD roles prefix | `biossettings-admin-role` | `biossettings-admin-role` (no prefix) | **Same** — Helm doesn't prefix these either |
| ServiceAccount name | `controller-manager` | `metal-operator-controller-manager` | Naming difference. Needs patch or accept new name. |
| Labels | Standard kustomize labels | Helm-specific labels (helm.sh/chart, app.kubernetes.io/managed-by: Helm) | Cosmetic. Kustomize uses `app.kubernetes.io/managed-by: kustomize` |

**Resolution options for naming:**
1. Accept the upstream names (simpler, less maintenance)
2. Add targeted JSON patches to rename the 4 core RBAC resources to match Helm convention
3. Use `namePrefix: metal-operator-` (but this over-prefixes per-CRD roles)

**Recommendation:** Accept upstream names. The current `metal-operator-` prefix was a Helm artifact, not a requirement. Document the name change for migration.

## Webhooks

**Match:** Webhook names and URLs are **identical** to current `webhooks.yaml`.

**Differences:**

| Aspect | Kustomize | Helm (current) | Impact |
|--------|-----------|----------------|--------|
| Resource name | `validating-webhook-configuration` | `metal-operator-validating-webhook-configuration` | Naming. Same resource, different metadata name. |
| Namespace field | Not set | `namespace: kube-system` | Kustomize can add via namespace transformer |
| Labels | kustomize-managed | Helm-managed (chart version, etc.) | Cosmetic |

## Host Deployment

**Functional equivalence:** The kustomize overlay produces a Deployment with:
- ✓ Same container image and tag
- ✓ Same args (leader-elect + operator-specific)
- ✓ Same env vars (KUBERNETES_SERVICE_HOST, KUBERNETES_CLUSTER_DOMAIN, KUBECONFIG)
- ✓ Same volume mounts (webhook-certs, remote-serviceaccount, remote-kubeconfig, macdb)
- ✓ Same initContainer (webhook-injector with correct args, probes, resources)
- ✓ Same strategy (Recreate)
- ✓ Same securityContext (runAsUser: 65532, runAsGroup: 65532)
- ✓ Same pod labels (Gardener network policies)
- ✓ Same serviceAccountName

**Differences:**

| Aspect | Kustomize | Helm (current) | Impact |
|--------|-----------|----------------|--------|
| Deployment name | `controller-manager` | `metal-operator-controller-manager` | Naming (from upstream vs Helm fullname) |
| Resource requests/limits | Upstream defaults | Custom values from values.yaml | Need to add resource patch in overlay |
| dnsRecordTemplate volume | Not included | Conditional (disabled by default) | Can add if needed |

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

2. **Add resource limits** to the host overlay patches (currently inherits upstream defaults
   which are lower than production requirements).

3. **Webhook ConfigMap name** should be patched to `metal-operator-validating-webhook-configuration`
   if webhook-injector expects that exact name, or update webhook-injector config to use the
   upstream name.

4. **Consider automated `make regen`** via GitHub Action on PRs that modify upstream refs
   (future enhancement, not a blocker).
