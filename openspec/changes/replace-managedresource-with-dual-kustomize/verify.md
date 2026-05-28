# Verification Report

> This file is produced by the `openspec-verify-change` skill after the apply phase
> completes, to confirm that the implementation is consistent with specs / design / tasks.
> Failed checks must be returned to the corresponding artifact for correction, then
> verify re-run.
>
> **STATUS: PRE-APPLY SCAFFOLD.** This file is committed at the design phase to capture
> the verification methodology — particularly the **manifest equivalence comparison
> between the legacy helm chart and the new dual-kustomize tree** (Section 6 below).
> When the apply phase completes, sections 1–5 are filled in with actual run results;
> section 6 is executed against the implementation and its results recorded; section 7
> tracks the cross-repo coordination status. Section 8 records the final decision.

**Change**: `replace-managedresource-with-dual-kustomize`
**Verified at**: `<YYYY-MM-DD HH:mm — fill in at verify time>`
**Verifier**: `<who / which agent — fill in at verify time>`

---

## 1. Structural Validation (`openspec validate --all --json`)

- [ ] All items return `"valid": true`

**Run**:
```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
openspec validate --all --json
```

**Result** (fill in at verify time):

```text
<paste openspec validate --all output summary here>
```

If any items failed, list id + issues:

| Item | Type | Issues |
|---|---|---|
| — | — | — |

---

## 2. Task Completion (`tasks.md`)

- [ ] All `- [ ]` have been changed to `- [x]`

**Run**:
```bash
grep -c '^- \[ \]' openspec/changes/replace-managedresource-with-dual-kustomize/tasks.md
# Expected at completion: 0
```

**Incomplete tasks** (if any):

| Task | Reason incomplete | Blocks archive? |
|---|---|---|
| — | — | — |

---

## 3. Delta Spec Sync State

For each capability directory under `openspec/changes/<name>/specs/`, compare against
the corresponding `openspec/specs/<capability>/spec.md`:

| Capability | Sync status | Notes |
|---|---|---|
| `kustomize-resource-splitting` | Needs sync (until Task 12 archive) | 7 ADDED, 5 MODIFIED, 1 REMOVED |
| `kustomize-sidecar-injection` | Needs sync (until Task 12 archive) | 4 ADDED, 1 MODIFIED |
| `webhook-url-rendering` | Needs sync (until Task 12 archive) | 3 REMOVED — capability becomes empty after archive |

After Task 12 (`openspec archive replace-managedresource-with-dual-kustomize`), all three SHALL flip to "Synced".

---

## 4. Design / Specs Coherence Spot Check

Sample check that `design.md` decisions are reflected in `specs/*.md` requirements
and scenarios:

| Sample item | design description | specs counterpart | Gap |
|---|---|---|---|
| ExternalName routing on workerless | § 3 "Webhook delivery via ExternalName + Git URL ref" | `kustomize-resource-splitting` ADDED "Webhook delivery via ExternalName routing" | None |
| caBundle invariant | § 3 "Critical invariant: kustomize tree MUST NOT emit caBundle" | `kustomize-sidecar-injection` ADDED "Kustomize tree must not emit caBundle in webhook configs" | None |
| Webhook-injector ca-rotation mode | § 4 "Webhook-injector sidecar — narrowed to caBundle-rotation-only" | `kustomize-sidecar-injection` ADDED "Webhook-injector sidecar configured for caBundle-rotation mode" | None |
| Drop Role→ClusterRole conversion | § 6 spec impact mention | `kustomize-resource-splitting` ADDED "Upstream RBAC applied verbatim" | None |
| Manager args restoration | § 2 repo layout mention | `kustomize-resource-splitting` MODIFIED "Host base overlay produces all seed cluster resources" with new "Manager Deployment customizations consolidated" scenario | None |
| Apply order is NOT a correctness requirement | § 1 topology + operational notes | `kustomize-resource-splitting` ADDED "System converges to working admission validation regardless of apply order" | None |
| Webhook content delivered live via Git URL ref (no pre-render) | § 3 webhook delivery flow | `kustomize-resource-splitting` ADDED "Build via kustomize Git URL ref consumes upstream live" | None |

**Drift warnings** (non-blocking):

- None at design phase. Re-check at verify time once implementation is complete.

---

## 5. Implementation Signal

- [ ] No unstaged files in worktree (`git status` clean apart from openspec/changes/...)
- [ ] All relevant commits pushed to `origin/poc/kustomize-metal-operator-remote`
- [ ] PR [#11633](https://github.com/sapcc/helm-charts/pull/11633) updated with Scope 3 description (per Task 9.4)

**Run**:
```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git status -s
git log --oneline master..HEAD
gh pr view 11633 --json updatedAt,body --jq '{updatedAt, hasScope3: (.body | contains("Scope 3"))}'
```

**Commit range** (fill in at verify time): `<from-sha>..<to-sha>`

---

## 6. Manifest Equivalence Verification (helm vs dual-kustomize)

> This is the **critical correctness check** for this change. The change transforms the
> deployment mechanism from helm + ManagedResource to dual-kustomize + ExternalName routing,
> but the **resulting cluster state must remain functionally equivalent**. Any divergence
> must be either explicitly intentional (and listed in section 6.4 below) or treated as a
> blocker until reconciled.
>
> **Where to run**: this comparison is most meaningful in `cc/kube-secrets` where per-cluster
> overlays exist and helm values files are alongside kustomize overlays. A partial comparison
> can be run in helm-charts (just bases vs helm render with placeholder values) but it's
> less useful. The kube-secrets coordinated change carries this comparison as part of its
> own verification (see kube-secrets `openspec/changes/replace-managedresource-with-dual-kustomize/`).

### 6.1 Methodology

For each target cluster (start with `rt-eu-de-1`, then `a-qa-de-200`):

1. **Helm-rendered baseline** — render the legacy helm chart with the cluster's values:
   ```bash
   cd /Users/D065300/IdeaProjects/sapcc/helm-charts
   helm template metal-operator-remote system/metal-operator-remote \
     --values /Users/D065300/IdeaProjects/sapcc/kube-secrets/values/helm/<clusterType>/<region>/<cluster>/metal-operator-remote.yaml \
     --namespace metal-operator-system \
     > /tmp/helm-rendered-<cluster>.yaml
   ```

2. **Kustomize-rendered output** — build both kustomize roots from the kube-secrets per-cluster overlay:
   ```bash
   cd /Users/D065300/IdeaProjects/sapcc/kube-secrets
   kustomize build values/kustomize/<clusterType>/<region>/<cluster>/metal-operator-remote/host/   > /tmp/kustomize-host-<cluster>.yaml
   kustomize build values/kustomize/<clusterType>/<region>/<cluster>/metal-operator-remote/remote/ > /tmp/kustomize-remote-<cluster>.yaml
   ```

3. **Split helm output by deployment target** — separate host-cluster resources from `ManagedResource`-wrapped workerless resources:
   ```bash
   # Host-cluster resources (everything that's NOT a ManagedResource or its wrapping Secret):
   yq -d'*' '. | select(.kind != "ManagedResource" and (.kind != "Secret" or .metadata.name | test("^mr-") | not))' \
     /tmp/helm-rendered-<cluster>.yaml > /tmp/helm-host-<cluster>.yaml

   # Workerless-cluster resources (unwrap the MR Secrets to extract data.objects.yaml content):
   yq -d'*' '. | select(.kind == "Secret" and (.metadata.name | test("^mr-"))) | .data["objects.yaml"]' \
     /tmp/helm-rendered-<cluster>.yaml | base64 -d \
     > /tmp/helm-remote-<cluster>.yaml
   ```

4. **Compare host side**:
   ```bash
   # Resource categorization:
   diff <(yq -d'*' '.kind' /tmp/helm-host-<cluster>.yaml | sort | uniq -c) \
        <(yq -d'*' '.kind' /tmp/kustomize-host-<cluster>.yaml | sort | uniq -c)

   # Resource names:
   diff <(yq -d'*' '.metadata.name + " (" + .kind + ")"' /tmp/helm-host-<cluster>.yaml | sort) \
        <(yq -d'*' '.metadata.name + " (" + .kind + ")"' /tmp/kustomize-host-<cluster>.yaml | sort)
   ```

5. **Compare workerless side**:
   ```bash
   # Resource categorization:
   diff <(yq -d'*' '.kind' /tmp/helm-remote-<cluster>.yaml | sort | uniq -c) \
        <(yq -d'*' '.kind' /tmp/kustomize-remote-<cluster>.yaml | sort | uniq -c)

   # Resource names:
   diff <(yq -d'*' '.metadata.name + " (" + .kind + ")"' /tmp/helm-remote-<cluster>.yaml | sort) \
        <(yq -d'*' '.metadata.name + " (" + .kind + ")"' /tmp/kustomize-remote-<cluster>.yaml | sort)
   ```

6. **Field-level deep diff** (for each resource pair, after normalization):
   ```bash
   # See section 6.5 below for normalization helpers (strip helm-managed-by labels,
   # release annotations, generated label keys, etc.)
   bash scripts/normalize-manifests.sh /tmp/helm-host-<cluster>.yaml > /tmp/helm-host-norm.yaml
   bash scripts/normalize-manifests.sh /tmp/kustomize-host-<cluster>.yaml > /tmp/kustomize-host-norm.yaml
   diff /tmp/helm-host-norm.yaml /tmp/kustomize-host-norm.yaml
   ```

### 6.2 Pass criteria

- ✓ **All host-cluster resource KINDS match** between helm-rendered and kustomize-rendered output (modulo intentional divergences in 6.4)
- ✓ **All host-cluster resource NAMES match** (modulo intentional divergences in 6.4)
- ✓ **All host-cluster resource SPECS functionally equivalent** (Deployment containers, Services, ConfigMaps, Secrets, RBAC, NetworkPolicies)
- ✓ **All workerless-cluster resource KINDS match** between unwrapped helm-MR-output and kustomize-rendered remote/ output (modulo intentional additions in 6.4: `system` Namespace + `webhook-service` ExternalName Service)
- ✓ **All workerless-cluster resource NAMES match** (modulo intentional additions)
- ✓ **All upstream RBAC applied verbatim** (Roles preserved as Roles, NOT converted to ClusterRoles — matches helm chart's behavior)
- ✓ **All 6 SAP manager args present** in both helm-rendered and kustomize-rendered controller-manager Deployment

### 6.3 Run results (fill in at verify time)

For each cluster:

| Cluster | Host-side categorization match? | Host-side names match? | Workerless-side categorization match? | Workerless-side names match? | Field-level diff acceptable? |
|---|---|---|---|---|---|
| `rt-eu-de-1` | — | — | — | — | — |
| `a-qa-de-200` | — | — | — | — | — |

**Documented divergences encountered** (fill in at verify time, cross-reference 6.4):

| Cluster | Resource | Divergence | Acknowledged in 6.4? |
|---|---|---|---|
| — | — | — | — |

### 6.4 Expected divergences (intentional, do NOT block)

These divergences are deliberate consequences of the change. They should appear in the diff but MUST NOT cause a verification failure:

| # | Divergence | helm side | kustomize side | Why intentional |
|---|---|---|---|---|
| 1 | Webhook `clientConfig` form on workerless | `clientConfig.url: https://metal-operator-webhook-service:443/<path>` | `clientConfig.service: { name: webhook-service, namespace: system, path: /<path> }` (no `caBundle` — populated by sidecar at runtime) | This change replaces URL rewrite with ExternalName-based routing. The new `webhook-service` ExternalName Service in workerless `system` namespace bridges the service-form lookup to the host's actual webhook service. |
| 2 | Workerless cluster has `system` Namespace | absent | present (`system-namespace.yaml`) | Required by the ExternalName Service (matches upstream's `clientConfig.service.namespace: system` placeholder) |
| 3 | Workerless cluster has `webhook-service` ExternalName Service | absent | present (`webhook-service-stub.yaml`) | Required for cross-cluster webhook routing in dual-kustomize topology |
| 4 | `caBundle` field in workerless `ValidatingWebhookConfiguration` | populated by helm-rendered output (or sidecar push, depending on chart version) | absent (sidecar populates at runtime; kustomize tree must NOT emit caBundle to avoid `kubectl apply` clobber) | Per `kustomize-sidecar-injection` spec: kustomize tree must not emit caBundle field |
| 5 | Local `webhook-config` ConfigMap on host | present (helm `templates/webhook-config.yaml` + `Files.Get "webhooks.yaml"`) | absent (deleted) | Sidecar narrows to caBundle-rotation mode; no longer reads a local ConfigMap. The workerless WebhookConfig is the source-of-truth. |
| 6 | Helm-managed-by labels / annotations | every resource has `app.kubernetes.io/managed-by: Helm`, `helm.sh/chart`, etc. | kustomize doesn't add these | kustomize doesn't have a Helm-equivalent label injection. Filter out before semantic diff. |
| 7 | Manager Deployment name | `metal-operator-controller-manager` (hardcoded in `templates/controller-manager.yaml` line 5) | `controller-manager` (inherited from upstream `config/manager` with no `namePrefix` in `host/base/kustomization.yaml`) | Pre-existing POC-stage decision flagged in brainstorm Open Questions — verify-phase action item: confirm no HPA/PDB/monitoring rules / runbooks reference the Deployment by name; if any do, document the cutover plan |
| 8 | Sidecar args / env | `--webhook-config-name=webhook-config` (push role) | `--webhook-config-name=validating-webhook-configuration` + `WEBHOOK_INJECTOR_MODE=ca-rotation` env var (caBundle-rotation role) | Coordinated with [`SAP-cloud-infrastructure/webhook-injector#9`](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9). Binary must support the new mode before production cutover. |
| 9 | Pre-rendered files removed | `system/metal-operator-remote/managedresources/{crds-and-rbac.yaml,namespace.yaml,rbac.yaml,webhooks.yaml}` are bundled with the chart | the kustomize tree consumes upstream `config/{crd,rbac,webhook}` via Git URL ref at every build | Eliminates pre-render commit cycle |
| 10 | Sidecar host-side Role no longer grants ConfigMap access | helm chart's `webhook-injector-rbac.yaml` grants `get,list,watch` on `configmaps` | kustomize tree's `webhook-injector-rbac.yaml` removes ConfigMap rule | Sidecar in ca-rotation mode no longer reads a local ConfigMap |

### 6.5 Normalization recipe (helper for 6.1 step 6)

A helper script that strips helm-only labels/annotations to enable semantic diff. Suggested location: `system/kustomize/metal-operator-remote/scripts/normalize-manifests.sh` (NEW, optional). Or run inline:

```bash
yq -i 'del(.metadata.labels."app.kubernetes.io/managed-by", .metadata.labels."helm.sh/chart", .metadata.labels."app.kubernetes.io/version", .metadata.labels."app.kubernetes.io/instance", .metadata.annotations."meta.helm.sh/release-name", .metadata.annotations."meta.helm.sh/release-namespace") | (.. | select(has("control-plane"))) // .' /tmp/<file>.yaml
```

Adjust filters per cluster as needed; document any cluster-specific normalization in the per-cluster comparison results.

### 6.6 Where this verification lives long-term

The kube-secrets coordinated change carries the canonical version of this comparison in its own `verify.md` because:
- helm values files live in `cc/kube-secrets/values/helm/<cluster>/metal-operator-remote.yaml`
- kustomize per-cluster overlays live in `cc/kube-secrets/values/kustomize/<cluster>/metal-operator-remote/`
- Both paths are co-located in kube-secrets, making the comparison naturally mechanical

**This change's verify.md (the file you're reading) covers**:
- The methodology and pass criteria
- Documented intentional divergences (single source-of-truth across both repos)
- Helm-charts-side partial smoke-test commands

**The kube-secrets verify.md covers**:
- The actual run results per cluster
- Field-level deep diff results
- Cluster-specific normalization decisions

---

## 7. Cross-repo coordination status

This change has hard dependencies on coordinated work in two other repositories.

### 7.1 `cc/kube-secrets` companion change

| Check | Status (fill in at verify time) | Notes |
|---|---|---|
| OpenSpec change scaffolded at `cc/kube-secrets:openspec/changes/replace-managedresource-with-dual-kustomize/` | ✓ pre-apply | Brainstorm + proposal complete locally on branch `openspec/replace-managedresource-with-dual-kustomize` |
| OpenSpec workflow complete in kube-secrets | — | design / specs / tasks / plan / verify |
| kube-secrets PR opened with Scope-3 dual-target pipeline + per-cluster overlay updates | — | Builds on PR #3905 |
| TEST-PHASE refs flipped to `?ref=master` after this PR merges | — | Per `move-cluster-overlays-to-kube-secrets` precedent |
| kube-secrets PR ready to merge in coordination with this PR | — | — |

### 7.2 `SAP-cloud-infrastructure/webhook-injector` binary

| Check | Status (fill in at verify time) | Notes |
|---|---|---|
| Issue [#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9) acknowledged by maintainers | — | Filed by ricogu |
| `WEBHOOK_INJECTOR_MODE=ca-rotation` mode (or equivalent) implemented | — | Out-of-repo PR |
| New webhook-injector image with the mode published to `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector` | — | Required for production cutover |
| Backward compatibility preserved: existing ConfigMap-as-source consumers still work | — | Per acceptance criteria #2 in the issue |

### 7.3 Verify image availability before production cutover

```bash
# Pull the published image and check for the mode signal:
docker run --rm keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest --help 2>&1 | grep -iE 'mode|ca-rotation' || echo "Mode not yet supported in published image — production cutover blocked"
```

**Note**: If image not yet published with the mode, this PR can still **merge to master** (pipelines stay in `triggers: "NOMATCH"` disabled state). Production cutover is gated until the image is available.

---

## 8. Overall Decision

- [ ] PASS — all checks clean, ready to proceed to docs gate (if applicable) and finishing-a-development-branch
- [ ] PASS WITH WARNINGS — may proceed but note: `<description, e.g. webhook-injector image not yet available; production cutover blocked but PR can merge to master>`
- [ ] FAIL — return to failed artifact for correction then re-run verify

**Next step** (fill in at verify time):

<describe the next action: archive, push, coordinate kube-secrets merge, etc.>
