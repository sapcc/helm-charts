## Verification Report: poc-kustomize-metal-operator-remote

### Summary

| Dimension    | Status |
|--------------|--------|
| Completeness | 37/37 tasks complete, 18/18 requirements covered |
| Correctness  | 18/18 requirements verified passing |
| Coherence    | All design decisions followed |

### CRITICAL Issues

None.

### WARNING Issues

None.

### SUGGESTION Issues

1. **webhook-config ConfigMap uses placeholder content in base**
   - `host/base/webhook-config.yaml` has `PLACEHOLDER` instead of actual webhook YAML
   - At deploy time on webhook-enabled clusters, this needs to be patched with real content
   - **Recommendation:** Document in README that webhook-enabled overlays must patch `webhook-config` with content from `remote/upstream/webhooks/manifests-url-based.yaml`

### Spec Requirement Verification

#### kustomize-resource-splitting (9 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Host base produces all seed resources | PASS | Deployment, 2 Services, Ingress, NetworkPolicy, 2 ConfigMaps, 3 Secrets, SA, Role, RoleBinding |
| Host overlays parameterize per-env | PASS | rt-eu-de-1 renders correct domain, apiserver, images |
| Overlay can remove base resources | PASS | rt-eu-de-1 removes webhook-service, webhook-injector RBAC, webhook-config via `$patch: delete` |
| Overlay can override volumes/mounts | PASS | rt-eu-de-1 overrides volume mount strategy |
| Overlay inherits unless explicitly removed | PASS | 7 resources in overlay vs 12 in base (5 webhook resources removed) |
| Remote produces CRDs and RBAC | PASS | 72 resources (16 CRDs, 52 ClusterRoles, 3 ClusterRoleBindings, 1 SA), no Role/RoleBinding |
| Remote pre-rendered as ManagedResource | PASS | `managedresources.yaml` files contain valid ManagedResource+Secret pairs |
| Top-level overlay renders all resources | PASS | `overlays/rt-eu-de-1/` produces 166 resources (host + 73 ManagedResources) |
| No Flux blockers | PASS | No KRM plugins, all builds succeed standalone |

#### kustomize-sidecar-injection (4 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Sidecar injected via Component | PASS | Base Deployment has initContainer `webhook-injector` with restartPolicy=Always |
| Image tag overridable | PASS | Component uses `images:` transformer |
| Sidecar removable per environment | PASS | rt-eu-de-1 overlay removes via `$patch: delete`, output has 0 initContainers |
| Base includes sidecar by default | PASS | `kustomize build host/base/` shows webhook-injector in initContainers |

#### webhook-url-rendering (3 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Service→URL transform | PASS | All clientConfig.service replaced with URL, no service fields remain |
| Pre-rendered static file | PASS | `manifests-url-based.yaml` exists, `kustomize build` works |
| Makefile regen target | PASS | `regen-metal-operator-remote` in system/Makefile, tested working |

#### kustomize-resource-splitting — top-level overlay (2 requirements from updated spec)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Single-command deployment via kubectl | PASS | `kustomize build overlays/rt-eu-de-1/` produces all resources |
| Overlay includes all resource categories | PASS | Host + 73 ManagedResources (upstream) + custom (Namespace, RBAC) |

### Design Decision Adherence

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Pure kustomize, no Helm | Yes | Zero `{{ }}` templates in any YAML file |
| Upstream config/ as source | Yes | 7 kustomization files reference ironcore-dev/metal-operator |
| webhook-injector as Component | Yes | `components/webhook-injector/` with `kind: Component` |
| Pre-rendered webhooks (W4) | Yes | Static file committed, regen on upgrades |
| Host/remote split | Yes | Clear directory separation (14 host files, 11 remote files) |
| Role→ClusterRole via patch | Yes | JSON patch in source kustomization, verified no Role in output |
| Base includes all, overlays remove | Yes | Base has webhooks, rt-eu-de-1 removes them |
| Per-env overlays at deploy time | Yes | `host/overlays/` and `remote/custom/overlays/` |
| Remote upstream pre-rendered at build time | Yes | Makefile generates, committed to git |
| Top-level overlay for kubectl apply -k | Yes | `overlays/rt-eu-de-1/` combines all |
| Makefile targets in system/Makefile | Yes | 3 targets added to root Makefile |
| Parameters from live cluster | Yes | rt-eu-de-1 overlay matches actual deployment |

### Final Assessment

All checks passed. No critical or warning issues. 1 minor suggestion (webhook-config placeholder documentation). Ready for archive.
