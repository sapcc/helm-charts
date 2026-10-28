# argora-operator-remote → DDO migration — Design

> **Status:** awaiting approval. THIRD chart migrated to dual-deployment-operator
> (DDO) after `metal-operator-remote` (live, Ready) and `boot-operator-remote`
> (merged, published). Same proven pattern; argora has a distinct shape (data CRs,
> vault credentials, no webhook, seed SA = `default`).
>
> **Scope approved by user (2026-10-28):** thin operand chart
> `system/argora-operator-remote-ddo` + DDO CR values in kube-secrets + an argora
> profile for the generalized cutover toolkit. Credentials model: vault-ref default
> in the operand chart values (metal's macdb pattern); data-CRs as mode=shoot
> addition templates driven by CR values. Naming: subchart
> `fullnameOverride: argora-operator` to match the live shoot RBAC identity exactly.

---

## 1. Intent & why

Migrate the `argora-operator-remote` deployment on cluster **m-qa-de-200** (seed
**a-qa-de-200**, namespace **shoot--cp--m-qa-de-200**) from the legacy Gardener
ManagedResource + Helm-release model to **DDO**-managed deployment, rendered from a
new operator-native operand chart `system/argora-operator-remote-ddo`
(mode=seed / mode=shoot).

**Why:** continue the fleet rollout replacing the pre-render-and-commit / GRM model
with DDO's two-render SSA model, moving per-cluster config into a
`DualDeploymentOperator` CR delivered from `cc/kube-secrets`. argora shares the seed
CP namespace with the already-migrated metal + boot operators and is the next slice.

**Why now:** metal + boot are proven on this exact cluster; the DDO controller is
installed and healthy. argora exercises the pattern on a chart with argora-specific
shape (data CRs + vault credentials), the last structural variation before the
remaining remote charts are mechanical.

## 2. Goals / non-goals / anti-goals

**Goals**
- A thin `system/argora-operator-remote-ddo` operand chart DDO renders twice.
- DDO CR values (defaults + a-qa-de-200 instance) added to the existing kube-secrets
  `dualDeploymentOperatorCRs` / `dualDeploymentOperatorCRDefaults` structure.
- An `argora-operator-remote` profile for the generalized cutover toolkit
  (`system/dual-deployment-operator/cutover/`).
- Preserve argora's 3 live management CRs (ClusterImport `mgmt-qa-de-200`,
  IPPoolImport `sci-k8s-management`, Update `mgmt-qa-de-200`) — data + UID preserved
  across re-ownership, all stay `Ready`. **One of them has real downstream state**:
  the IPPoolImport has produced a live `GlobalInClusterIPPool`
  `globalinclusterippool-mgmt-qa-de-200` (`10.219.139.128/26`, 29 total, **1 address
  already allocated**) — so preservation is not merely cosmetic (see §3 topology note).

**Non-goals**
- Migrating any other remote chart, or argora on any cluster other than m-qa-de-200.
- Changing the upstream `argora` subchart or its pinned version.
- Touching the legacy `argora-operator-remote` GRM consumers on `rt-*` runtime
  clusters (they keep the legacy chart).

**Anti-goals**
- Breaking the legacy `argora-operator-remote` chart for non-DDO clusters.
- An immutable-selector collision leaving two controllers churning.
- Loss/recreation of the 3 argora CRs' data (the ippool prefix / cluster bindings).
- Leaking BMC/netbox credentials onto the shoot (the subchart's credentials Secret
  must stay seed-side).

## 3. Constraints (cluster-authoritative unless noted)

- **argora has NO webhook and NO webhook-injector** (subchart ships no webhook
  template). → no cert, no VWC, no sidecar, no `rewriteWebhookURL`/caBundle
  transformation. Like boot, simpler than metal.
- **Seed Deployment uses SA `default`** (live-confirmed) — the legacy overlay sets
  `argora-operator-core.manager.serviceAccountName: default`. → **NO seed-SA gap**
  that bit boot; no seed SA additions template needed.
- **The manager pod ALWAYS mounts a mandatory credentials Secret** (subchart
  `templates/extras/secret.yaml`, `credentials.json` from `.Values.credentials`).
  The seed render MUST emit it. The subchart emits it whenever `manager.enable=true`,
  so the seed render covers it — no separate additions template.
- **Vault credentials** (`bmcUser`/`bmcPassword`/`netboxToken`) are `vault+kvv2://`
  refs today in the kube-secrets overlay. DDO has no vault/overlay step (metal's
  macdb problem). The admin-k3s helm-diff secrets-injector-validator gate **forbids
  vault refs in a non-Secret kind**, so they must NOT sit in the DDO CR. →
  **`credentials` lives (region-generic, with `vault+kvv2://` refs) in the operand
  chart `values.yaml` under `argora-operator-core.credentials`**; the subchart's
  `extras/secret.yaml` renders them into the seed Secret; secrets-injector resolves
  them in-cluster. Use the `${REGION}` token + `replace` substitution exactly as
  metal's `macdb.yaml` does — NOT `tpl` (the `{{ resolve }}` directive is for
  secrets-injector, not Helm).
- **Data CRs** (ClusterImport/IPPoolImport/Update, group `argora.cloud.sap`) are
  live & `Ready` in **kube-system on the mgmt cluster = the shoot**. Unique to
  argora. → authored as **mode=shoot addition templates** in the operand chart,
  data driven by CR `values` (`clusterImport`/`ipPoolImport`/`update` maps),
  namespace `kube-system`, mirroring the legacy wrapper's own
  `managedresources/{cluster-import,ippool-import,updates}.yaml` (which place them in
  kube-system — NOT the subchart's `resources/*.yaml` which use `argora-system`). The
  per-cluster data is small and non-secret → fine in the CR.
- **⚠ Cluster topology (u8s-VERIFIED 2026-10-28) — this cluster's CR data is QA
  scaffolding, but NOT inert.** a-qa-de-200 is a **single-node k3s** (one node
  `admin1.garden2.cc.qa-de-1.cloud.sap`, `control-plane,master`), so there is **no
  real `mgmt-qa-de-200` managed cluster**: `get clusters.cluster.x-k8s.io -A` on
  m-qa-de-200 returns **No resources found**, i.e. the `Ready` ClusterImport/Update
  (`mgmt-qa-de-200`) reconcile against a cluster that does not exist — QA scaffolding
  on this cluster. **However** the IPPoolImport (`sci-k8s-management`) HAS produced a
  real `GlobalInClusterIPPool` `globalinclusterippool-mgmt-qa-de-200`
  (`10.219.139.128/26`, **USED 1**), so it is live state, not scaffolding — preserve
  it carefully. On **prod admin clusters** (qa-de-1 and other prod regions) the
  `mgmt-<region>` ClusterImport/Update target REAL management clusters; the operand
  chart + CR-values structure (`clusterImport`/`ipPoolImport`/`update` maps driven by
  CR values) MUST stay general enough to carry that real prod data — do NOT hard-code
  the qa-de-200 scaffolding shape. This a-qa-de-200 migration is like-for-like:
  preserve the 3 CRs exactly as live, same UID, via protect-then-teardown (§5).
- **Chart version must be clean semver** (metal lesson: `_sha` suffix → "improper
  constraint" → SeedRenderFailed). Start `0.1.0`, bump patch per change.
- **Images: GHCR default in the public chart, keppel mirror override in kube-secrets.**
  argora image default `ghcr.io/sapcc/argora`; kube-secrets base already overrides
  repository to `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/sapcc/argora`.
- **`charts/*.tgz` is gitignored** (root `.gitignore` `*.tgz`). Commit only
  `Chart.lock`.
- **Subchart pin:** `argora 0.0.1-20261023094418-9e2ccc2-crds` from
  `oci://ghcr.io/sapcc/charts` (identical to the legacy chart's Chart.lock) so the
  DDO render matches the live controller.
- **Naming / identity (⚠ load-bearing).** The live shoot RBAC uses `argora-operator-*`
  names: SA `argora-operator-controller-manager` @ kube-system, ClusterRole
  `argora-operator-manager-role`, CRB `argora-operator-manager-rolebinding` → that SA.
  The token-requestor kubeconfig the controller uses to reach the shoot is minted for
  SA `argora-operator-controller-manager` @ kube-system. The operand chart therefore
  sets **`argora-operator-core.fullnameOverride: argora-operator`** so the subchart's
  shoot SA/CRB/CR render byte-identical to today, and the controller keeps
  authenticating as the same SA across cutover. **Validated by render** (helm
  template seed+shoot). Note the seed Deployment then also renders as
  `argora-operator-controller-manager` (vs the live `argora-remote-controller-manager`);
  acceptable because DDO uninstalls the legacy release first (SeedFirst + Recreate),
  so there is no name/selector collision.
- **Selector parity.** Live seed Deployment selector:
  `app.kubernetes.io/name: argora-operator-core`, `control-plane: controller-manager`
  (the subchart's `argora.name` yields the alias `argora-operator-core`). The DDO seed
  render must reproduce it; any additions Service/NetworkPolicy selectors must match.
- **Shared namespace** — ~9 releases share shoot--cp--m-qa-de-200. Teardown ownership
  by `meta.helm.sh/release-name` annotation, NEVER a name prefix.
- **CRD keepObjects:** the legacy CRD MRs (`mr-crd-*`) have `keepObjects: true` →
  uninstall preserves the 3 **CRD schemas**.
- **⚠ Data-CR MRs do NOT have keepObjects (cluster-authoritative).** The legacy
  `managedresource.yaml` applies `keepObjects: true` ONLY to `kind:
  CustomResourceDefinition`. Live check: `mr-ci-mgmt-qa-de-200`,
  `mr-ippi-sci-k8s-management`, `mr-u-mgmt-qa-de-200` all have `keepObjects` **unset
  (= false)**. → **A naive `helm uninstall` of `argora-operator-remote` DELETES the 3
  live management CRs** (ClusterImport/IPPoolImport/Update); GRM removes the CR objects
  even though the CRD schema survives. DDO re-creating them from CR values yields
  **new UIDs** and a reconcile gap. This is the argora analogue of metal's
  namespace-cascade hazard and it makes the stated UID-preservation invariant
  **unachievable without an explicit protect-before-teardown step** (see §5, resolved
  with user).

## 4. Approaches considered

### 4a. The operand chart shape

**Decided:** thin wrapper (same rationale as boot/metal — DDO can't render the legacy
mode-less, MR-wrapping chart, and mutating the legacy chart breaks `rt-*` GRM
consumers). **The controller Deployment is rendered by the subchart** (no
hand-authored Deployment): argora needs no init-container/sidecar/extra volume the
subchart can't express — `manager.volumes[].source` wires the `remote-kubeconfig`
exactly as the legacy chart does, and `credentials` drives the mandatory Secret.

```
system/argora-operator-remote-ddo/
  Chart.yaml            # dep: argora subchart (same pin), alias argora-operator-core
  Chart.lock            # committed; charts/*.tgz gitignored
  values.yaml           # fullnameOverride(subchart)=argora-operator; subchart flags OFF;
                        #   argora-operator-core.credentials with vault+kvv2 refs (${REGION})
  templates/
    _helpers.tpl        # mode guards + chart.labels/selectorLabels/additionsAnnotations
    remote-kubeconfig.yaml   # Secret, token-requestor (mode=seed) [additions]
    data-crs.yaml            # ClusterImport/IPPoolImport/Update (mode=shoot) [additions]
    [networkpolicy.yaml]     # (mode=seed) — ONLY if legacy overlay has one; see §8
  ci/
    no-mode-default.sh  # copy from boot: asserts values.yaml has no `mode`
    selector-parity.sh  # copy/adapt from boot
```

No webhook-*, no macdb, no dns-record, no controller-manager (subchart renders it),
no ingress (argora has no iPXE/registry ingress — confirm in §8), no metrics Service
additions (subchart metrics stays seed-side, pruned from shoot).

**Per-mode subchart enablement via CR seed/shootValues** (metal/boot convention B for
the subchart; chart-side `mode` guards A for the additions):
- `seedValues.argora-operator-core`: `manager.enable: true`,
  `rbac/crd/metrics/prometheus/certManager.enable: false`, `ironcore.enable: true`.
- `shootValues.argora-operator-core`: `crd.enable: true`, `rbac.enable: true`,
  `metrics.enable: true` (legacy shoot bundle had metrics on — see §8 fidelity check),
  `manager.enable: false`, rest false.

### 4b. kube-secrets CR delivery

**No new pipeline.** The CR is delivered by the already-wired
`dual-deployment-operator` release (admin-k3s pipeline → shoot--cp--m-qa-de-200).
argora becomes a third entry alongside metal + boot in the same two files:
- `values/helm/admin-k3s/dual-deployment-operator.yaml` →
  `dualDeploymentOperatorCRDefaults.argora-operator-remote` (shootNamespace kube-system,
  applyOrder SeedFirst, source repo/name, keppel image override, seed/shootValues,
  netbox/ironcore/readiness args, the `filterKinds` transformation).
- `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` →
  `dualDeploymentOperatorCRs.argora-operator-remote` (per-cluster diff: enabled,
  source.version, shootAccess.server, KUBERNETES_SERVICE_HOST, global.region/
  clusterType, and the data-CR values clusterImport/ipPoolImport/update).

**shootNamespace:** `kube-system` (argora SA + CRs live there). **No webhook
transformations.** **One `filterKinds` transformation** to drop the subchart's
credentials `Secret` and metrics `Service` from the **shoot** render
(`source: upstream`, kinds `[Secret, Service]`) — reproducing the legacy make filter
(`yq select(kind != Service and != ... and != Secret)`); the seed keeps the Secret
(the pod mounts it) and the additions-origin data-CRs are spared (origin = additions).

> **Dependency (flagged to user):** SCI #1542 may relocate ALL DDO CR delivery into a
> dedicated chart fleet-wide. User chose to proceed with the existing
> `dualDeploymentOperatorCRs` pattern now; if #1542 lands, argora's CR migrates with
> the fleet. Not a blocker.

### 4c. Cutover tooling

Reuse the generalized toolkit from **PR #13167** (`feat/ddo-cutover-toolkit`, open vs
master — `system/dual-deployment-operator/cutover/`). Add
`profiles/argora-operator-remote.env`:
- `RELEASE=argora-operator-remote`, `DDO_CR=argora-operator-remote`,
  `LEGACY_CHART_DIR=system/argora-operator-remote`, `ROLLOUT_ORDER=30`.
- `DEPLOY=argora-operator-controller-manager` (post-cutover name under the DDO render;
  see naming note — the live legacy name is `argora-remote-controller-manager`, so the
  scanner's "release present" check keys off the Helm release, not the Deployment
  name).
- `CONTROLLER_POD_SELECTOR="app.kubernetes.io/name=argora-operator-core"`.
- `CRD_GROUPS="argora.cloud.sap"`.
- `NAMESPACE_CASCADE_GATE="off"` (argora owns no namespace).
- `FREEZE_KINDS_CLUSTER=""`;
  `FREEZE_KINDS_NS="clusterimports.argora.cloud.sap ippoolimports.argora.cloud.sap updates.argora.cloud.sap"`.
- `FREEZE_SERVER_STATES=0` (no hardware state machine).
- `OPERAND_CHART_DIR=system/argora-operator-remote-ddo`.
- `BASELINE_SNAPSHOT_KINDS_NS="clusterimports.argora.cloud.sap ippoolimports.argora.cloud.sap updates.argora.cloud.sap"`
  — snapshot the 3 CRs pre-uninstall so verify asserts data + UID preserved.
- `VERIFY_SAMPLE=""` — argora's CRs are the cluster's OWN management CRs (no foreign
  tenant object like boot's `mig-test-metal`). The do-no-harm invariant is CR-data/UID
  preservation, covered by the baseline snapshot, not an external sample.

> **Dependency (flagged to user):** PR #13167 is not yet on master. The argora
> helm-charts branch should either branch off `feat/ddo-cutover-toolkit` or declare
> the merge dependency so the profile lands on the toolkit. Builder confirms sequencing.

## 5. The cutover shape (boot specifics → argora specifics)

Same coordinated single-window cutover, **with an argora-specific protect step**:
```
protect 3 data-CR MRs (keepObjects:true) → verify → uninstall argora-operator-remote
  → (merge DDO CR PR, reconcile) → DDO renders, adopts CRs via SSA & applies
```
argora specifics:
- **⚠ Protect-then-teardown (resolved with user 2026-10-28).** BEFORE uninstall, patch
  the 3 data-CR ManagedResources — `mr-ci-mgmt-qa-de-200`,
  `mr-ippi-sci-k8s-management`, `mr-u-mgmt-qa-de-200` — to `spec.keepObjects: true`
  and verify the patch is live. Then uninstall leaves the 3 CR objects in place; DDO
  adopts them via SSA with identical spec → **same UID, no reconcile gap, data
  intact**. This is the direct analogue of metal's namespace-cascade `keepObjects`
  patch. The argora cutover profile/runbook MUST carry this as a **required gate**
  (the generic toolkit's protect mechanism, parameterised like metal's
  `NAMESPACE_CASCADE_GATE` but targeting these 3 MRs — see §8 for the exact profile
  wiring the builder must add, since the current toolkit only models a single
  namespace-MR protect). Back up each MR + CR before patching (user's standing
  "back up before live patch" directive).
- **No Namespace-cascade risk** (owns no namespace) → the namespace gate stays `off`.
- **Freeze gate minimal**: assert no argora CR (clusterimports/ippoolimports/updates)
  is Terminating. No hardware state machine.
- **CR re-ownership, not deletion**: with the protect step, the 3 argora CRs survive
  with data + UID intact and end `Ready` after DDO re-applies them (same spec → SSA
  no-op on data). keepObjects:true on the CRD MRs additionally protects the CRD
  schemas.
- **Credentials continuity**: the seed credentials Secret is re-emitted by the DDO
  seed render (subchart) with the same vault-resolved content; the pod restarts with
  the same mount.

## 6. Branch / PR hygiene

- ONE feature branch off `master` → ONE PR per repo (user preference; no stacked
  PRs). Proposed branch: `feat/argora-operator-remote-ddo-m-qa-de-200`.
- Two repos → two PRs: helm-charts (public, `GH_HOST=github.com`): operand chart +
  cutover profile; kube-secrets (internal, `GH_HOST=github.wdf.sap.corp`): CR values.
- **CODEOWNERS:** add `/system/argora-operator-remote-ddo` matching the LEGACY
  `/system/argora-operator-remote` owners:
  `@sapcc/PlusOne-CE-API-Services-ControlPlane @sapcc/baremetal` (a reviewer required
  this for boot/metal — match legacy).
- **Publish precondition** (metal lesson): the operand chart version MUST be published
  to keppel before the kube-secrets CR referencing it merges (else SeedRenderFailed).
  Verify: `helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/argora-operator-remote-ddo --version X`.

## 7. Verification path (cluster-authoritative)

- `helm dependency build && helm template --set mode=seed|shoot` renders clean.
  - **seed**: controller Deployment (selector `argora-operator-core` +
    `control-plane: controller-manager`, SA `default`), credentials Secret
    (`argora-operator-secret`), remote-kubeconfig Secret.
  - **shoot**: 3 CRDs + SA `argora-operator-controller-manager` + ClusterRole
    `argora-operator-manager-role` + CRB `argora-operator-manager-rolebinding` (subject
    that SA @ kube-system) + the 3 data-CRs; credentials Secret and metrics Service
    pruned by the `filterKinds` transformation.
- Full shoot-RBAC inventory diffed against the legacy
  `managedresources/crds-and-rbac.yaml` (kind + name + rules); any divergence
  documented in the chart README (metal/boot precedent).
- Image pullability verified on-cluster (`kubectl run` the keppel ref) — already live
  (controller 1/1), low risk.
- Post-cutover: DDO CR `argora-operator-remote` Ready=True; controller Deployment
  recreated, DDO-owned (`owned-by` label), 1/1; 3 CRDs owned-by stamped, UID unchanged
  vs baseline; the 3 argora CRs Ready, same UID, data intact.
- **CR-preservation acceptance check (manual, metal/boot precedent — builder-check Q2,
  settled call):** after cutover, manually diff the 3 argora CRs (name, UID, `.spec`)
  against the pre-uninstall baseline snapshot and confirm `Ready`. This is a manual
  acceptance gate in the runbook, NOT a new automated toolkit check (the toolkit's
  automated UID assertion covers CRDs, not data CRs).
- Dry-run `cutover-ddo.sh --operator argora --phase uninstall --dry-run` passes all
  read-only gates (including the new data-CR protect gate) before any live step.
- CI `no-mode-default.sh` + `selector-parity.sh` pass.

## 8. Left to the builder

- **Shoot-RBAC fidelity vs legacy** (Task gate): render the DDO operand shoot bundle
  vs the legacy `managedresources/crds-and-rbac.yaml`, diff the full object list. The
  legacy shoot render set `metrics.enable: true` — confirm whether `metrics.enable`
  in shootValues is needed to close the RBAC/ServiceMonitor gap, or whether it only
  adds a (pruned) metrics Service. Set shootValues to reproduce the legacy grant
  functionally ≥; document any deviation in the README.
- **Does the legacy a-qa-de-200 overlay define a NetworkPolicy or Ingress for argora?**
  Recon showed none in the overlay, but confirm against the rendered legacy manifest
  before deciding whether the operand chart needs `networkpolicy.yaml` / `ingress.yaml`
  additions. If absent, omit them (argora is a netbox/ironcore reconciler, not an
  iPXE/registry server).
- **Data-CR template fidelity**: reproduce the legacy wrapper's
  `managedresources/{cluster-import,ippool-import,updates}.yaml` exactly (ns
  kube-system, same `.spec` shape: ClusterImport `spec.clusters`, IPPoolImport
  `spec.ippools`, Update `spec.clusters`). Confirm the rendered `.spec` matches the
  live CR specs (ClusterImport `{clusters:[{name:mgmt-qa-de-200}]}`, IPPoolImport the
  `sci-k8s-management` ippool block, Update `{clusters:[{name:mgmt-qa-de-200}]}`).
- **`owner-info` dependency**: legacy chart has it; metal/boot operand charts dropped
  it. Decide by render parity, not cargo-cult (likely drop).
- **Exact chart version** (start 0.1.0) and keppel publish/CI mechanics.
- **PR #13167 sequencing**: branch off the toolkit branch or declare the dependency.
- **Data-CR protect gate wiring in the toolkit (from §5):** the current toolkit
  models a single namespace-MR protect (`NAMESPACE_CASCADE_GATE`). argora needs a
  *list* of data-CR MRs patched to `keepObjects:true` before uninstall. Builder adds a
  profile field (e.g. `PROTECT_MRS="mr-ci-mgmt-qa-de-200 mr-ippi-sci-k8s-management mr-u-mgmt-qa-de-200"`)
  and the generic protect/verify/rollback logic in `lib/ddo-common.sh`, keeping it
  operator-agnostic (metal's namespace gate and argora's MR-list gate are two shapes of
  the same "protect before teardown" barrier). Fail-closed on any read error, back up
  each MR + CR first.
- **`${REGION}` substitution** in the operand chart `credentials` default — confirm the
  vault paths that are region-specific (`qa-de-1/metal-api/remoteboards/...`) vs
  shared (`shared/daybreak/netbox-auth`); only the region-specific ones carry the token.
