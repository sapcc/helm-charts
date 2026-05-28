## Why

The kustomize POC ([archived change `2026-05-13-poc-kustomize-metal-operator-remote`](openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote)) introduced per-cluster kustomize overlays for `metal-operator-remote` directly into this repo at `system/kustomize/metal-operator-remote/{host,remote/custom}/overlays/<cluster>/` and `system/kustomize/metal-operator-remote/overlays/<cluster>/`, violating the established convention that all cluster-specific configuration lives in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets). This change removes those per-cluster overlays for clusters `rt-eu-de-1` and `a-qa-de-200` (their new home is established by the companion change in kube-secrets) and updates two capability specs accordingly. Tracking: [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169).

## What Changes

**Per-cluster kustomize overlays — removed**
- From: 6 overlay paths in helm-charts:
  - `system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1/`
  - `system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200/`
  - `system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1/`
  - `system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200/`
  - `system/kustomize/metal-operator-remote/overlays/rt-eu-de-1/`
  - `system/kustomize/metal-operator-remote/overlays/a-qa-de-200/`
- To: those paths no longer exist in this repo. Per-cluster overlays live in `cc/kube-secrets` at `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`. They reference helm-charts bases via kustomize Git URL refs (`https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/<base-path>?ref=master`).
- Reason: convention restoration — cluster-specific configuration belongs in kube-secrets.
- Impact: breaking for any external consumer that relied on the in-tree overlay paths (none known — the kube-secrets companion change becomes the consumer). Apply order ensures kube-secrets has the overlays first, before this deletion lands.

**`kustomize-resource-splitting` capability spec — MODIFIED + REMOVED requirements**
- From: spec mandates per-cluster overlays at `host/overlays/<cluster-name>/`, `remote/custom/overlays/<cluster-name>/`, and top-level `overlays/<cluster-name>/` in helm-charts.
- To: those requirements are REMOVED (with Reason and Migration). The spec retains the host vs. remote split, base/component requirements, and `MUST_BE_SET_IN_OVERLAY` fail-loud requirements. A new section cross-references `cc/kube-secrets` capability `cluster-overlay-layout` for per-cluster overlay placement and wiring.
- Reason: the per-cluster overlay paths in helm-charts no longer exist after this change.
- Impact: spec readers in helm-charts now find an explicit pointer to the kube-secrets capability that owns overlay placement.

**`kustomize-sidecar-injection` capability spec — small MODIFIED**
- From: spec includes cluster-specific usage examples for the webhook-injector Component (e.g., `$patch: delete` removal of webhook resources for ENABLE_WEBHOOKS=false in `rt-eu-de-1`).
- To: cluster-specific scenarios are removed. The Component contract (image override, `restartPolicy: Always` initContainer, integration semantics) stays.
- Reason: cluster-specific usage examples reference the moved overlays.
- Impact: spec stays focused on the Component contract, which is the helm-charts concern.

**`webhook-url-rendering` capability spec — UNCHANGED**
- From / To: no change.
- Reason: this spec covers a build-time `yq` transform on upstream manifests; entirely unaffected by overlay placement.
- Impact: none.

**README update at `system/kustomize/metal-operator-remote/README.md`**
- From: in-tree overlay descriptions ("Add a new environment overlay" section, lines 92–116, references `host/overlays/<cluster>/` and similar in-tree paths).
- To: a new "Per-cluster overlays" section pointing to `cc/kube-secrets/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/` as the canonical location, with a one-line example. The "Add a new environment" instructions move to point at kube-secrets.
- Reason: replace stale in-tree references with current locations.
- Impact: future readers know where to look.

## Capabilities

### New Capabilities

None. This change adds no new capabilities. (The new `cluster-overlay-layout` capability is added in the kube-secrets companion change.)

### Modified Capabilities

- `kustomize-resource-splitting`: requirements about per-cluster overlay placement in helm-charts are REMOVED (with Migration pointing at kube-secrets capability). Host/remote split, bases, components, `MUST_BE_SET_IN_OVERLAY` requirements stay. New cross-reference to `cluster-overlay-layout`.
- `kustomize-sidecar-injection`: cluster-specific usage scenarios are MODIFIED (removed cluster-specific examples; Component contract unchanged).

## Impact

**Affected paths in this repo:**
- `system/kustomize/metal-operator-remote/host/overlays/{rt-eu-de-1,a-qa-de-200}/` — deleted.
- `system/kustomize/metal-operator-remote/remote/custom/overlays/{rt-eu-de-1,a-qa-de-200}/` — deleted.
- `system/kustomize/metal-operator-remote/overlays/{rt-eu-de-1,a-qa-de-200}/` — deleted.
- `system/kustomize/metal-operator-remote/README.md` — updated.
- `openspec/specs/kustomize-resource-splitting/spec.md` — delta applied at archive (after merge).
- `openspec/specs/kustomize-sidecar-injection/spec.md` — delta applied at archive (after merge).

**Untouched in this repo:**
- `system/kustomize/metal-operator-remote/host/base/`, `remote/upstream/`, `remote/custom/base/`, `remote/custom/components/{prod,qa}/`, `components/webhook-injector/` — bases / components stay; consumed by kube-secrets overlays via Git URL refs.
- `system/kustomize/metal-operator-remote/Makefile`, regen scripts — unchanged.
- `system/metal-operator-remote/` (the legacy Helm chart at `Chart.yaml version: 0.6.5`) — entirely untouched. It continues to drive the production deploy until operators flip clusters to the kustomize pipeline (separate future activity).
- `openspec/specs/webhook-url-rendering/spec.md` — unchanged.

**Cross-repo dependencies:**
- Companion change in `cc/kube-secrets`: `openspec/changes/move-cluster-overlays-to-kube-secrets/`. Apply order: kube-secrets first, this repo second. See companion `proposal.md` for the kube-secrets-side details and the exhaustive task list.

**Branch / PR:**
- This change lands on the existing `poc/kustomize-metal-operator-remote` branch and combines with the open PR there. The PR was originally opened for the now-archived kustomize POC change; the PR description must be updated when this change is added to reflect the combined scope.
- No new feature branch is created. No new PR is opened.

**External impact:**
- None on production deploys: the legacy Helm pipeline at kube-secrets's `pipelines/metal-operator-remote-{admin-k3s,runtime}/` continues to deploy from `system/metal-operator-remote/` (the Helm chart). The kustomize tree's per-cluster overlays are not yet in any production deploy path; their removal here does not affect any running cluster.
- Any external consumer that depended on `system/kustomize/metal-operator-remote/{host/overlays,remote/custom/overlays,overlays}/<cluster>/` paths in helm-charts must migrate to `cc/kube-secrets/values/kustomize/<type>/<region>/<cluster>/metal-operator-remote/`. None are known.

**Validation gate before merge:**
- Every kube-secrets overlay must build successfully against helm-charts after this PR's deletions. Two validation methods support different review states:
  - **Method A** (direct, kube-secrets merged): clone kube-secrets master, run `kustomize build` against each overlay — kustomize fetches helm-charts master via HTTPS.
  - **Method B** (local-path rewrite, kube-secrets on feature branch): clone the kube-secrets PR branch into a throwaway directory, rewrite `https://github.com/sapcc/helm-charts.git//<path>?ref=<anything>` to the local helm-charts checkout path, run `kustomize build`. This validates the post-merge state without requiring kube-secrets to have merged first — the normal review-time scenario.
- Both methods documented in `tasks.md` (Tasks 4A / 4B) and `plan.md` (Steps 4A.x / 4B.x). Pre-flight Task 1.1 detects state.
- Either method failing means the deletion is removing something a kube-secrets overlay still references — investigate, restore, or coordinate a base change.
