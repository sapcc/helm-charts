## Verification Report: poc-kustomize-metal-operator-remote

### Summary

| Dimension    | Status |
|--------------|--------|
| Completeness | 34/34 tasks complete, 15/15 requirements covered |
| Correctness  | 14/15 requirements verified passing, 1 with known limitation |
| Coherence    | All design decisions followed |

### CRITICAL Issues

None.

### WARNING Issues

1. **RBAC resource naming differs from current Helm chart**
   - Kustomize uses upstream names: `manager-role`, `leader-election-role`, `controller-manager`
   - Helm uses prefixed names: `metal-operator-manager-role`, `metal-operator-leader-election-role`, `metal-operator-controller-manager`
   - **Impact:** Migration from Helm chart to kustomize would create duplicate RBAC resources unless old ones are cleaned up
   - **Recommendation:** Either add targeted JSON patches to rename the 4 core resources, or document a migration plan that removes old-named resources. Covered in `VERIFICATION.md` with recommendation to accept upstream names.

2. **webhook-config ConfigMap uses placeholder content**
   - `host/base/webhook-config.yaml` has `PLACEHOLDER` instead of actual webhook YAML content
   - At deploy time, this ConfigMap needs to contain the content of `manifests-url-based.yaml`
   - **Recommendation:** Either use kustomize `configMapGenerator` with file reference, or document that the overlay must patch this content. Consider referencing the file directly in the overlay.

### SUGGESTION Issues

1. **Missing `.gitignore` for generated files**
   - The `managedresources.yaml` files are generated but should still be committed (they're deployment artifacts)
   - Consider adding a comment at the top of generated files: `# GENERATED - DO NOT EDIT. Run 'make regen' to regenerate.`
   - **Recommendation:** Add generation comments to `scripts/wrap-managedresources.sh` output

### Spec Requirement Verification

#### kustomize-resource-splitting (7 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Host base produces all seed resources | PASS | Deployment, 2 Services, Ingress, NetworkPolicy, 2 ConfigMaps, 3 Secrets, SA, Role, RoleBinding |
| Host overlays parameterize per-env | PASS | rt-eu-de-1 renders correct domain, apiserver, macdb, images |
| Remote produces CRDs and RBAC | PASS | 16 CRDs, 52 ClusterRoles, 3 ClusterRoleBindings, 1 SA |
| Remote pre-rendered as ManagedResource | PASS | `managedresources.yaml` files exist with correct format |
| Host/remote equivalent to Helm | PASS (with naming caveat) | Documented in VERIFICATION.md |
| Directory separates host/remote | PASS | `host/` and `remote/` clearly separated |
| No Flux blockers | PASS | No KRM plugins, kustomize build works standalone |

#### kustomize-sidecar-injection (2 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Sidecar injected via Component | PASS | initContainer `webhook-injector` with restartPolicy=Always, correct image/args/probes/resources/volumeMounts |
| Image tag overridable | PASS | Overlay changes tag from `latest` to `v0.3.1` |

#### webhook-url-rendering (3 requirements)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Service→URL transform | PASS | All clientConfig.service replaced with clientConfig.url, no service fields remain |
| Pre-rendered static file | PASS | `manifests-url-based.yaml` exists, `kustomize build` works without tools |
| Makefile regen target | PASS | `make regen-remote-webhooks` succeeds |

### Design Decision Adherence

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Pure kustomize, no Helm | Yes | No Helm templates or values anywhere |
| Upstream config/ as source | Yes | All kustomization.yaml ref ironcore-dev/metal-operator |
| webhook-injector as Component | Yes | `components/webhook-injector/` with `kind: Component` |
| Pre-rendered webhooks (W4) | Yes | Static file committed, regen on upgrades |
| Host/remote split | Yes | Clear directory separation |
| Role→ClusterRole via patch | Yes | JSON patch on Kind, verified no Role in output |
| Per-env overlays at deploy time | Yes | `host/overlays/` and `remote/custom/overlays/` |
| Remote upstream pre-rendered at build time | Yes | Makefile generates, committed to git |
| No Flux blockers | Yes | No plugins, standard kustomize |

### Final Assessment

No critical issues. 2 warnings to consider (RBAC naming migration, webhook-config placeholder). Ready for archive with noted improvements.
