# ipam-capi-remote → DDO (layered kustomize) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `ipam-capi-remote` on `m-qa-de-200` to dual-deployment-operator two-render SSA delivery via a layered kustomize overlay tree, a kube-secrets `source.kustomize` DualDeploymentOperator CR, and a cutover profile — preserving the two live `GlobalInClusterIPPool` UIDs and the cross-operator RBAC exactly.

**Architecture:** A new kustomize overlay tree `system/ipam-capi-remote-ddo/` (public helm-charts) laid out as the DDO-tested fixture dictates — `base/` (shared, renders to both), `additions/seed/` + `additions/shoot/` (SAP-added resources, stamped `dual-deployment-operator.cc.sap/origin: additions`), and `seed/` + `shoot/` entrypoints that compose them. DDO git-clones the `?ref=`-pinned tree from inside the seed, runs `kustomize build seed/` and `kustomize build shoot/`, then SSA-applies each render into the respective cluster (seed = `a-qa-de-200`, shoot = `m-qa-de-200`). CRDs are vendored (not remote-base) to match the live `v0.21.0` bundle. The webhook URL is identical in both renders so no `rewriteWebhookURL`; only two injector-target-label patches are applied via CR transformations.

**Tech Stack:** kustomize (kustomize.config.k8s.io/v1beta1), Kubernetes CRDs (controller-gen v0.21.0 output), Gardener ManagedResource-free SSA delivery, DDO `dual-deployment-operator.cc.sap/v1alpha1`, `u8s kubectl`, GitHub (public helm-charts + internal kube-secrets).

**Spec:** `docs/superpowers/specs/2026-10-30-ipam-capi-remote-ddo-migration-design.md`

## Global Constraints

- Source model = `source.kustomize` (NOT `source.helm`); overlay tree git-pinned via `?ref=`. No Chart.yaml, no helmify, no keppel chart publish.
- `fullnameOverride=ipam-capi` identities are load-bearing — every rendered object name MUST match live: Deployment `ipam-capi-controller-manager`; shoot SA `ipam-capi-controller-manager` @ `kube-system`; webhook-injector SA/Service `ipam-capi-remote-webhook-injector` / `ipam-capi-remote-webhook-service`; webhook configs `ipam-capi-remote-{mutating,validating}-webhook-configuration`.
- CRDs vendored in `shoot/crds/` MUST match the LIVE `v0.21.0` bundle field-for-field (upstream v1.1.1 commit `7933583138cf` used controller-gen v0.17.2 → live was SAP-regenerated). Reproduce labels/annotations: `clusterctl.cluster.x-k8s.io/move-hierarchy: ""` label, `cluster.x-k8s.io/provider: ipam-in-cluster` label, cert-manager CA-injection annotation on IPPool + GlobalIPPool CRDs.
- Cross-operator RBAC re-layered VERBATIM: `ipam-capi-metal-rolebinding` / `ipam-capi-metal-admin-rolebinding` bind `metal-operator-controller-manager`@`kube-system` to `ipam-capi-manager-role` / `ipam-capi-manager-admin-role` (ipaddressclaims get/list/patch/update/watch/create/delete); plus `ipam-capi-remote-leader-election-role` + `ipam-capi-remote-webhook-injector` ClusterRoles + CRBs → `ipam-capi-controller-manager`@`kube-system`.
- SAP-added resources (token-requestor Secret, remote-kubeconfig ConfigMap, webhook-injector sidecar + RBAC/metrics/servicemonitor, webhook Service) live under `additions/<mode>/` and MUST carry `commonAnnotations: {dual-deployment-operator.cc.sap/origin: additions}`.
- Controller pinned to **v1.1.1** — no image/API/CRD-version upgrade. Image default `registry.k8s.io/capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`; keppel override `keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1` set via a kustomize `images:` transformer in the seed overlay (NOT CR values).
- webhook-injector image default `ghcr.io/sap-cloud-infrastructure/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976` (r7 target-patch build); keppel override `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector` (NOT `cloud-infrastructure-dev`).
- `shootNamespace: kube-system` (shoot SA lives there); data pools go to `metal-servers` via the pool resource's own `namespace:` field.
- r7 webhook-injector sidecar args: DROP `--webhook-config-name` / `--managed-resource-label` / `--external-host` / `--external-port`; ADD `--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote`; KEEP `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`, `--leader-election-id=ipam-capi-remote-webhook-injector-leader`, `--cert-secret-name=ipam-capi-remote-cert-secret`, `--cert-sans=ipam-capi-remote-webhook-service`, `--rotation-overlap-window=30s`, `--rotation-gate-timeout=30s`; FIX the securityContext path bug (point at `.podSecurityContext`, not `.manager.podSecurityContext`); ports metrics 8082 / health 8083; mounts webhook-certs→`/tmp/webhook-certs` + remote-serviceaccount + remote-kubeconfig.
- Transformations in the CR: NO `rewriteWebhookURL` (ipam webhooks are already url-based and the service name is identical seed+shoot — it would be a no-op); TWO `patch` transformations (one per webhook-config kind) applying the injector target label.
- Shared-namespace ownership is by `meta.helm.sh/release-name`-equivalent (DDO `OwnedByLabel`), never name prefix.
- Branch `feat/ipam-capi-remote-ddo-m-qa-de-200`; ONE PR per repo. Strict merge order: helm-charts overlay PR merges → push/tag the `?ref=` → kube-secrets CR PR merges → live cutover.
- Vault refs are forbidden in the CR (secrets-injector-validator); none needed here.

## Review Focus

- **Wrong-cluster delivery.** A resource mis-placed in `base/` (renders to both) or in the wrong `additions/<mode>/` lands on the wrong cluster — e.g. the controller Deployment reaching the shoot, or a CRD reaching the seed. Test: `kustomize build seed/` contains the Deployment/webhook Service/sidecar RBAC and NO CRDs; `kustomize build shoot/` contains the 7 CRDs + controller RBAC + webhook configs and NO Deployment.
- **CRD field drift breaking live-pool adoption.** A vendored CRD that differs from the live `v0.21.0` bundle (openAPI schema, served/storage versions, printerColumns, conversion, or the move-hierarchy/provider labels) risks a schema-rejection or re-validation of the 2 live pools. Test: field-for-field diff of each vendored CRD against the live bundle is empty.
- **Cross-operator RBAC narrowing.** Dropping or altering the metal↔ipam bindings silently breaks metal-operator's ipaddressclaims access. Test: rendered shoot RBAC contains both metal rolebindings and the exact verbs, byte-compared against the legacy `managedresources/rbac.yaml`.
- **Accidental pool emission on a-qa-de-200.** If the shoot overlay references `pools.yaml`, DDO would create/adopt a pool and could clobber the 2 out-of-band UIDs. Test: `kustomize build shoot/` for the a-qa-de-200 ref emits ZERO `GlobalInClusterIPPool`.
- **additions origin-stamp missing.** A SAP-added resource without `dual-deployment-operator.cc.sap/origin: additions` is indistinguishable from an upstream object to DDO's provenance logic. Test: every object from `additions/<mode>/` carries the annotation in the render.

---

## Task 1: Scaffold the overlay tree skeleton + base

**Files:**
- Create: `system/ipam-capi-remote-ddo/base/kustomization.yaml`
- Create: `system/ipam-capi-remote-ddo/seed/kustomization.yaml`
- Create: `system/ipam-capi-remote-ddo/shoot/kustomization.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/kustomization.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/shoot/kustomization.yaml`
- Test: `system/ipam-capi-remote-ddo/tests/render_test.sh` (bash+kustomize render assertions; established here, extended by later tasks)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the four-dir layout (`base/`, `additions/{seed,shoot}/`, `seed/`, `shoot/`) with `seed/` = `resources: [../base, ../additions/seed]` and `shoot/` = `resources: [../base, ../additions/shoot]`; `additions/*/kustomization.yaml` carry `commonAnnotations: {dual-deployment-operator.cc.sap/origin: additions}`. Later tasks append resource filenames to these kustomizations.

- [ ] **Step 1: Write the failing test** — `tests/render_test.sh` asserts `kustomize build seed/` and `kustomize build shoot/` both exit 0 and that the `base/` kustomization has no resources yet (empty render is valid at this stage). Assert the `additions/{seed,shoot}/kustomization.yaml` each contain the exact `commonAnnotations` line.
- [ ] **Step 2: Run to verify it fails** — `bash system/ipam-capi-remote-ddo/tests/render_test.sh`; Expected: FAIL (dirs/files absent).
- [ ] **Step 3: Create the five kustomization.yaml files** mirroring `dual-deployment-operator/internal/source/testdata/kustomize/` (base empty resources list; additions with origin annotation; seed/shoot composing `../base` + `../additions/<mode>`).
- [ ] **Step 4: Run to verify it passes** — `bash system/ipam-capi-remote-ddo/tests/render_test.sh`; Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): scaffold layered kustomize overlay skeleton`.

## Task 2: Vendor the 7 CRDs (shoot) matching the live v0.21.0 bundle

**Files:**
- Create: `system/ipam-capi-remote-ddo/shoot/crds/*.yaml` (7 files — 4 provider pool CRDs + 3 core CAPI: `clusters.cluster.x-k8s.io`, `ipaddresses.ipam.cluster.x-k8s.io`, `ipaddressclaims.ipam.cluster.x-k8s.io`)
- Modify: `system/ipam-capi-remote-ddo/shoot/kustomization.yaml` (append `crds/*.yaml` to resources)
- Create: `system/ipam-capi-remote-ddo/tests/crd_diff_test.sh`

**Interfaces:**
- Consumes: Task 1 shoot kustomization.
- Produces: vendored CRD files that later RBAC/webhook/pool tasks assume exist in the shoot render.

- [ ] **Step 1: Write the failing test** — `crd_diff_test.sh` renders `kustomize build shoot/`, extracts each CustomResourceDefinition, and diffs it field-for-field against the live bundle captured from the cluster (`u8s kubectl --context m-qa-de-200 get crd <name> -o yaml` normalized — strip `metadata.{resourceVersion,uid,generation,creationTimestamp,managedFields}` and status). The 7 CRD names are: `globalinclusterippools.ipam.cluster.x-k8s.io`, `globalinclusterprefixpools.ipam.cluster.x-k8s.io`, `inclusterippools.ipam.cluster.x-k8s.io`, `inclusterprefixpools.ipam.cluster.x-k8s.io`, `ipaddresses.ipam.cluster.x-k8s.io`, `ipaddressclaims.ipam.cluster.x-k8s.io`, `clusters.cluster.x-k8s.io`. Assert the diff is empty for all 7, and assert presence of the `clusterctl.cluster.x-k8s.io/move-hierarchy` label, `cluster.x-k8s.io/provider: ipam-in-cluster` label, and cert-manager CA-injection annotation on the IPPool + GlobalIPPool CRDs.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no CRDs vendored).
- [ ] **Step 3: Generate + vendor the CRDs** — run the same pinned kustomize bases the legacy tree uses (provider `//config/crd?ref=v1.1.1` + `//config/rbac?ref=v1.1.1`, 3 core CAPI raw files @ `v1.14.2`), reconcile the controller-gen stamp to the live `v0.21.0` form, write the 7 files, and append `crds/*.yaml` to the shoot kustomization resources.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS (all 7 diffs empty, labels/annotations present).
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): vendor CAPI-IPAM v1.1.1 CRDs matching live v0.21.0 bundle`.

## Task 3: Shoot controller RBAC incl. cross-operator metal bindings (verbatim)

**Files:**
- Create: `system/ipam-capi-remote-ddo/shoot/rbac.yaml`
- Modify: `system/ipam-capi-remote-ddo/shoot/kustomization.yaml` (append `rbac.yaml`)
- Create: `system/ipam-capi-remote-ddo/tests/rbac_fidelity_test.sh`

**Interfaces:**
- Consumes: Task 2 CRDs.
- Produces: shoot SA `ipam-capi-controller-manager`@`kube-system`, the upstream ipam roles/bindings, and the cross-operator metal bindings — names other tasks' webhook/CR transformations reference.

- [ ] **Step 1: Write the failing test** — `rbac_fidelity_test.sh` renders `kustomize build shoot/`, extracts all `ClusterRole`/`ClusterRoleBinding`/`Role`/`RoleBinding`/`ServiceAccount`, and byte-compares (normalized) the cross-operator set against the legacy `system/kustomize/ipam-capi-remote/managedresources/rbac.yaml`: assert both metal rolebindings with subject `metal-operator-controller-manager`@`kube-system`, `ipam-capi-manager-admin-role` carries `ipaddressclaims` verbs `[get,list,patch,update,watch,create,delete]`, and the leader-election + webhook-injector ClusterRoles/CRBs bind `ipam-capi-controller-manager`@`kube-system`.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.
- [ ] **Step 3: Author `shoot/rbac.yaml`** — combine the upstream provider `config/rbac@v1.1.1` roles with the legacy `managedresources/rbac.yaml` SAP additions verbatim; append to shoot kustomization.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): shoot controller RBAC with cross-operator metal bindings`.

## Task 4: Shoot webhook configurations (url-based)

**Files:**
- Create: `system/ipam-capi-remote-ddo/shoot/webhooks.yaml`
- Modify: `system/ipam-capi-remote-ddo/shoot/kustomization.yaml` (append `webhooks.yaml`)
- Create: `system/ipam-capi-remote-ddo/tests/webhook_parity_test.sh`

**Interfaces:**
- Consumes: Task 2 CRDs (webhook rules target the 4 pool kinds).
- Produces: `ipam-capi-remote-mutating-webhook-configuration` + `ipam-capi-remote-validating-webhook-configuration`, each with `clientConfig.url: https://ipam-capi-remote-webhook-service:443/...` — the target of the CR's two label patches (Task 8).

- [ ] **Step 1: Write the failing test** — `webhook_parity_test.sh` renders `kustomize build shoot/` and asserts both webhook configs exist with all 8 webhooks (4 mutating + 4 validating) carrying url-based clientConfigs to `https://ipam-capi-remote-webhook-service:443/{mutate,validate}-ipam-cluster-x-k8s-io-v1alpha2-*`, matching the legacy `system/ipam-capi-remote/webhooks.yaml` byte-for-byte (normalized).
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.
- [ ] **Step 3: Author `shoot/webhooks.yaml`** — port the legacy url-based `webhooks.yaml` verbatim (no injector label yet — that is a CR transformation); append to shoot kustomization.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): shoot mutating+validating webhook configurations`.

## Task 5: Shape-agnostic pool template (shoot additions, un-referenced by a-qa-de-200)

**Files:**
- Create: `system/ipam-capi-remote-ddo/additions/shoot/pools.example.yaml` (documented, NOT listed in any current overlay's resources)
- Modify: `system/ipam-capi-remote-ddo/additions/shoot/kustomization.yaml` (resources list stays WITHOUT the pool for a-qa-de-200)
- Create: `system/ipam-capi-remote-ddo/tests/no_pool_test.sh`

**Interfaces:**
- Consumes: Task 2 GlobalInClusterIPPool CRD.
- Produces: a reusable pool resource future clusters add to their overlay; fixes the legacy duplicate-`spec:` bug.

- [ ] **Step 1: Write the failing test** — `no_pool_test.sh` asserts `kustomize build shoot/` emits ZERO `GlobalInClusterIPPool` (a-qa-de-200 has none), AND that `pools.example.yaml` is valid YAML with a single `spec:` block (regression on the legacy duplicate-`spec:` bug) in `metal-servers` namespace, `ipam.cluster.x-k8s.io/v1alpha2`.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (example file absent / bug present).
- [ ] **Step 3: Author `pools.example.yaml`** porting the legacy data-CR shape (addresses/excludedAddresses/prefix/gateway, ns metal-servers) with the duplicate-`spec:` removed; do NOT add it to the resources list.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): shape-agnostic pool example (unreferenced for a-qa-de-200)`.

## Task 6: Seed controller Deployment + webhook-injector sidecar (r7) + token-requestor + webhook Service

**Files:**
- Create: `system/ipam-capi-remote-ddo/additions/seed/deployment.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/webhook-service.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/webhook-injector-rbac.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/webhook-injector-metrics-service.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/webhook-injector-servicemonitor.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/remote-kubeconfig-secret.yaml`
- Create: `system/ipam-capi-remote-ddo/additions/seed/remote-kubeconfig-configmap.yaml`
- Modify: `system/ipam-capi-remote-ddo/additions/seed/kustomization.yaml` (resources + `images:` transformer)
- Create: `system/ipam-capi-remote-ddo/tests/seed_render_test.sh`

**Interfaces:**
- Consumes: Task 1 additions/seed kustomization.
- Produces: Deployment `ipam-capi-controller-manager` (manager container + r7 sidecar initContainer), Service `ipam-capi-remote-webhook-service` (443→9443), webhook-injector SA/RBAC `ipam-capi-remote-webhook-injector`, static token-requestor Secret `ipam-capi-remote-kubeconfig`, remote-kubeconfig ConfigMap.

- [ ] **Step 1: Write the failing test** — `seed_render_test.sh` renders `kustomize build seed/` and asserts: Deployment named `ipam-capi-controller-manager` with manager container image `registry.k8s.io/capi-ipam-ic/...:v1.1.1` overridden by the `images:` transformer to the keppel `ccloud-gcr-mirror` path; an initContainer running the webhook-injector with the EXACT r7 arg set (ADDs `--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote`, DROPs the 4 dead flags) and securityContext from `.podSecurityContext`; the 7 gardener networking podLabels; webhook Service `ipam-capi-remote-webhook-service` 443→9443; token-requestor Secret `ipam-capi-remote-kubeconfig` with the gardener token-requestor labels/annotations; and that EVERY object carries `dual-deployment-operator.cc.sap/origin: additions`.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.
- [ ] **Step 3: Author the 7 resource files** porting from `system/kustomize/ipam-capi-remote/manager/*` + legacy chart templates, applying the r7 sidecar port and the securityContext bug fix; add the `images:` transformer (controller keppel mirror) to the seed kustomization. webhook-injector image default `ghcr.io/sap-cloud-infrastructure/webhook-injector:sha-f85df8e3...` also overridden to the keppel `i-cant-believe-its-not-cloud-infrastructure-dev` mirror via the transformer.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ipam-capi-remote-ddo): seed Deployment, r7 injector sidecar, token-requestor, webhook Service`.

## Task 7: Full render gate + mode-isolation assertions

**Files:**
- Modify: `system/ipam-capi-remote-ddo/tests/render_test.sh` (aggregate gate)
- Create: `system/ipam-capi-remote-ddo/README.md` (overlay role, mode contract, upstream-update procedure, CRD regen steps)

**Interfaces:**
- Consumes: Tasks 1–6.
- Produces: the authoritative render gate both CI and the cutover scanner invoke.

- [ ] **Step 1: Write the failing test** — extend `render_test.sh` to assert mode isolation: `seed/` render contains the Deployment + webhook Service + injector RBAC and ZERO CustomResourceDefinition; `shoot/` render contains all 7 CRDs + controller RBAC + both webhook configs and ZERO Deployment/webhook Service; neither render contains a resource missing its expected origin treatment.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL if any resource is mis-placed.
- [ ] **Step 3: Fix any mis-placement** surfaced, and write the README (mode contract = structural overlays, no `mode` flag; upstream-update procedure per design §3).
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `test(ipam-capi-remote-ddo): full render + mode-isolation gate; add README`.

## Task 8: kube-secrets DualDeploymentOperator CR (source.kustomize)

**Files:**
- Modify: `values/helm/admin-k3s/dual-deployment-operator.yaml` (base: `dualDeploymentOperatorCRDefaults.ipam-capi-remote`)
- Modify: `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` (instance: `dualDeploymentOperatorCRs.ipam-capi-remote`)
- Test: `yamllint` + `helm template`/CI validator per repo convention (render assertion script if present)

**Interfaces:**
- Consumes: the published overlay tree (git `?ref=`).
- Produces: the live CR DDO reconciles. (This is the kube-secrets repo at `/Users/D065300/IdeaProjects/sapcc/kube-secrets`, INTERNAL — `gh` CLI with `GH_HOST=github.wdf.sap.corp --repo cc/kube-secrets`; separate branch/PR.)

- [ ] **Step 1: Write the failing test** — a render/validate check asserting the base defaults map contains `ipam-capi-remote` with `shootNamespace: kube-system`, `applyOrder: SeedFirst`, `source.kustomize.{url (helm-charts `//system/ipam-capi-remote-ddo/...?ref=…`), seedPath: seed, shootPath: shoot}`, `shootAccess.secretName: dual-deployment-operator-shoot-access`, and TWO `patch` transformations (one targeting kind `MutatingWebhookConfiguration`, one `ValidatingWebhookConfiguration`) each strategic-merging `metadata.labels.dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote`, and NO `rewriteWebhookURL`. Instance overlay asserts `enabled: true` + `shootAccess.server: https://api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap` + the per-cluster `?ref=`.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (keys absent).
- [ ] **Step 3: Author both CR blocks** mirroring metal's shape, adapted to `source.kustomize`; zero vault refs.
- [ ] **Step 4: Run to verify it passes** — Expected: PASS (validator clean).
- [ ] **Step 5: Commit** (in kube-secrets worktree) — `feat(ddo): ipam-capi-remote DualDeploymentOperator CR (source.kustomize)`.

## Task 9: Cutover profile

**Files:**
- Create: `system/dual-deployment-operator/cutover/profiles/ipam-capi-remote.env`
- Test: `system/dual-deployment-operator/cutover/tests/` (profile-lint per toolkit convention)

**Interfaces:**
- Consumes: the overlay tree (`OPERAND_OVERLAY_DIR`), the live cluster.
- Produces: the profile `cutover-ddo.sh --operator ipam-capi-remote` sources. (Toolkit lives on branch `feat/ddo-cutover-toolkit`; fold into the helm-charts PR or its own per user preference.)

- [ ] **Step 1: Write the failing test** — a profile-lint asserting the required keys: `RELEASE=ipam-capi-remote`, `DDO_CR=ipam-capi-remote`, `LEGACY_CHART_DIR=system/ipam-capi-remote`, `ROLLOUT_ORDER=40`, `DEPLOY=ipam-capi-controller-manager`, `CONTROLLER_POD_SELECTOR=control-plane=controller-manager,app.kubernetes.io/name=ipam-capi-remote`, `CRD_GROUPS=ipam.cluster.x-k8s.io`, `NAMESPACE_CASCADE_GATE=off`, `PROTECT_MRS=''`, `FREEZE_KINDS_NS=globalinclusterippools.ipam.cluster.x-k8s.io`, `BASELINE_SNAPSHOT_KINDS_NS=globalinclusterippools.ipam.cluster.x-k8s.io`.
- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.
- [ ] **Step 3: Author the profile** with those exact values + a comment that the 2 out-of-band pool UIDs (`83614ed7-…`, `d7d99994-…`) must survive (assert, nothing to protect).
- [ ] **Step 4: Run to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(ddo-cutover): ipam-capi-remote profile`.
