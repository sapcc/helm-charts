# ipam-capi-remote → DDO migration — Design

> **Status:** awaiting approval. FOURTH operator migrated to dual-deployment-operator
> (DDO) after `metal-operator-remote` (live, Ready), `boot-operator-remote` (merged,
> published), and `argora-operator-remote` (live, Ready). ipam's defining shape is
> **a webhook + webhook-injector sidecar**, making `metal-operator-remote` the closest
> reference for the *webhook mechanics* — but ipam diverges on the **source model**.
>
> **Scope approved by user (2026-10-30):** deliver ipam to DDO via a **layered
> kustomize overlay tree** (`source.kustomize`), **not** a Helm operand chart. The three
> deliverables are: (1) a new kustomize overlay tree in `helm-charts` (base + seed
> overlay + shoot overlay), git-pinned by `?ref=`; (2) a `DualDeploymentOperator` CR in
> kube-secrets using `source.kustomize{url, seedPath, shootPath}`; (3) an ipam profile
> for the generalized cutover toolkit.
>
> **Architecture decisions confirmed this session:**
> 1. **`source.kustomize`, layered overlay** (user chose "Layered kustomize overlay").
>    This is a deliberate divergence from the 3 prior `source.helm` charts. I had
>    soft-recommended Helm for fleet consistency; user overrode — both were verified
>    viable. (Decision-Discipline: user instruction > my recommendation; deviation noted.)
> 2. The legacy `system/kustomize/ipam-capi-remote/` helmify-INPUT tree is **not reused**
>    — it collapses entirely into the new DDO overlay tree (no helmify step at all).
> 3. The legacy `build-ipam-capi-remote` make target and `system/ipam-capi-remote` chart
>    stay untouched until cutover is proven; the DDO work is purely additive.

---

## 1. Intent & why

Migrate the `ipam-capi-remote` deployment for cluster **m-qa-de-200** from the legacy
Gardener ManagedResource + Helm-release model to **DDO**-managed deployment. DDO renders
a kustomize overlay **twice** — once for `seed` (→ the controller runs on seed
`a-qa-de-200`) and once for `shoot` (→ CRDs/RBAC/webhook-configs/data-CRs are stored on
the Metal-API shoot `m-qa-de-200`) — and Server-Side-Applies each render directly into
the corresponding cluster.

> **Topology / terminology (authoritative — SCI Gardener architecture doc).**
> `m-qa-de-200` is the **Metal-API cluster**: a *workerless* shoot that only **stores**
> the IPAM custom resources (the `GlobalInClusterIPPool` data CRs + the pool CRDs). The
> **controller itself runs on the seed** `a-qa-de-200`, in namespace
> `shoot--cp--m-qa-de-200`, and reaches the shoot's API server through a token-requestor
> kubeconfig. So the **seed render** targets `a-qa-de-200` (Deployment, webhook-injector
> sidecar, webhook Service, injector RBAC/metrics/servicemonitor, token-requestor Secret,
> remote-kubeconfig ConfigMap) and the **shoot render** targets `m-qa-de-200` (pool +
> core CAPI CRDs, controller RBAC incl. the cross-operator metal binding, the Mutating +
> Validating webhook configurations, and the `GlobalInClusterIPPool` data CRs).

Why DDO: one operator reconciles the seed-side controller and the shoot-side CRDs/RBAC as
a single unit, replacing the brittle two-headed legacy model (a Helm release on the seed
+ hand-rolled Gardener ManagedResources shipping objects to the shoot).

Why kustomize here specifically: ipam has **no upstream Helm chart** (the
cluster-api-ipam-provider-in-cluster ships only kustomize bases), the SAP additions are
naturally expressed as kustomize patches over those upstream bases, and the DDO
`source.kustomize` seed/shoot *path* split maps cleanly onto the two renders without any
Helm `mode` flag. Both source models were proven viable this session (see §4); the user
chose kustomize.

---

## 2. Goals / non-goals / anti-goals

**Goals**
- ipam-capi-remote on `m-qa-de-200` fully reconciled by DDO (seed controller + shoot
  CRDs/RBAC/webhooks), replacing the legacy Helm-release + ManagedResource delivery.
- **Preserve the two live `GlobalInClusterIPPool` CRs** on `m-qa-de-200` with their UIDs
  and allocations intact across cutover (`globalinclusterippool-mgmt-qa-de-200`,
  UID `83614ed7-f367-4bd0-acdd-4fbd4de76eec`, `10.219.139.128/26`, 1 allocation; `test`,
  UID `d7d99994-c27d-4116-835b-4d858069b7ea`, 0 used).
- Reproduce the webhook wiring exactly: the single in-cluster webhook endpoint
  (`ipam-capi-remote-webhook-service:443`) is **identical in both renders**, so no URL
  rewrite is needed (see §4.3); the webhook-injector sidecar targets the shoot via
  `--target-label`, and the `dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote`
  label is patched onto **both** the Mutating and the Validating webhook configuration.
- Preserve the **cross-operator RBAC** verbatim (metal-operator-controller-manager's
  access to ipam `ipaddressclaims`).
- Stay pinned to controller **v1.1.1** (migration is a delivery-mechanism change only).

**Non-goals**
- No controller/image upgrade; no CRD API-version changes; no pool data changes.
- No change to the legacy chart or its make target until cutover is verified.
- No rollout to clusters other than `m-qa-de-200` / `a-qa-de-200` in this change.

**Anti-goals (would make this a failure even if it "works")**
- Any change to the live pool UIDs or their allocations.
- Any widening/narrowing of the cross-operator RBAC surface.
- Introducing a Helm `mode` default or any construct DDO rejects at render time.
- Reaching for `source.helm` fleet-consistency shortcuts that re-introduce helmify.

---

## 3. Constraints (cluster-authoritative facts)

These are verified against the live clusters and the DDO operator source; they bind the
implementation regardless of source model.

- **Webhook + sidecar.** ipam has a `MutatingWebhookConfiguration`
  (`ipam-capi-remote-mutating-webhook-configuration`) and a
  `ValidatingWebhookConfiguration` (`ipam-capi-remote-validating-webhook-configuration`),
  4 pool kinds each (`{,global}inclusterippool`, `{,global}inclusterprefixpool` @
  `ipam.cluster.x-k8s.io/v1alpha2`), all `failurePolicy: Fail`, `clientConfig.url`
  `https://ipam-capi-remote-webhook-service:443/{mutate,validate}-…`. A webhook-injector
  sidecar provisions the serving cert and patches the `caBundle`.
- **`fullnameOverride: ipam-capi` is load-bearing** — the live identities must be matched
  exactly: Deployment `ipam-capi-controller-manager`; shoot SA
  `ipam-capi-controller-manager` @ `kube-system`; injector SA/Service
  `ipam-capi-remote-webhook-injector` / `ipam-capi-remote-webhook-service`; webhook
  configs `ipam-capi-remote-{mutating,validating}-webhook-configuration`. Pod/selector
  labels: `control-plane: controller-manager` + `app.kubernetes.io/name=ipam-capi-remote`
  (+ instance).
- **CRDs match the LIVE `v0.21.0` bundle field-for-field.** Upstream v1.1.1
  (commit `7933583138cf`) was generated with controller-gen `v0.17.2`; the live bundle
  shows `v0.21.0`, i.e. SAP re-generated it. The vendored CRDs must reproduce the LIVE
  bundle (the UID/field authority), including the `clusterctl.cluster.x-k8s.io/move-hierarchy: ""`
  **label**, the `cluster.x-k8s.io/provider: ipam-in-cluster` common label, and the
  cert-manager CA-injection annotation on the `InClusterIPPool` + `GlobalInClusterIPPool`
  CRDs. Pool CRD served-version shape: IPPools serve `v1alpha1` (storage:false) +
  `v1alpha2` (storage:true); PrefixPools serve `v1alpha2` only (storage). 7 CRDs total on
  the shoot (4 provider pool kinds + core CAPI `ipaddresses`, `ipaddressclaims`,
  `clusters.cluster.x-k8s.io`).
- **Cross-operator RBAC — preserve verbatim.** `ipam-capi-metal-rolebinding` /
  `ipam-capi-metal-admin-rolebinding` grant `metal-operator-controller-manager`
  (@ `kube-system`) the ipam `manager-role` / `manager-admin-role` (`ipaddressclaims`
  get/list/patch/update/watch/create/delete). Plus the remote leader-election role and the
  webhook-injector ClusterRole + bindings → `ipam-capi-controller-manager` @ `kube-system`.
- **Data CRs are out-of-band.** The 2 live pools carry no MR-origin annotation and no
  chart labels — they were NOT chart-delivered. The `a-qa-de-200` overlay therefore sets
  **no pools**, so the shoot render emits zero `GlobalInClusterIPPool` and DDO does not
  adopt or own them; they simply continue to exist. The overlay still ships a
  shape-agnostic pool template for future clusters. Consequence for cutover:
  `PROTECT_MRS=''` (nothing to protect-then-teardown); the 7 CRD MRs are already
  `keepObjects: true`.
- **webhook-injector r7 sidecar args** (vs the legacy pre-r7 form): DROP
  `--webhook-config-name` / `--managed-resource-label` / `--external-host` /
  `--external-port`; ADD `--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote`;
  KEEP `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`,
  `--leader-election-id=ipam-capi-remote-webhook-injector-leader`,
  `--cert-secret-name=ipam-capi-remote-cert-secret`,
  `--cert-sans=ipam-capi-remote-webhook-service`, `--rotation-overlap-window=30s`,
  `--rotation-gate-timeout=30s`. Fix the legacy securityContext bug (read
  `.podSecurityContext`, not `.manager.podSecurityContext`). Pin the image (not `:latest`).
  Ports metrics 8082 / health 8083; mounts `webhook-certs`→`/tmp/webhook-certs` +
  `remote-serviceaccount` + `remote-kubeconfig`.
- **Images.** Controller public default
  `registry.k8s.io/capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`; keppel
  override (set by the kustomize `images:` transformer in the overlay, since the seed has
  no registry.k8s.io egress)
  `keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`.
  webhook-injector public default `ghcr.io/sap-cloud-infrastructure/webhook-injector`
  (metal's r7 build `sha-f85df8e3d55165e3b6e1117f6b120624268d0976`); keppel override
  `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector`
  (metal-verified mirror — **not** `cloud-infrastructure-dev`, which lacks these tags).
- **Clean semver**; shared-namespace ownership on the seed is by the
  `meta.helm.sh/release-name` annotation (≈9 releases share `shoot--cp--m-qa-de-200`) —
  not a name prefix.
- **`shootNamespace: kube-system`** (the shoot SA lives there); the data pools go to the
  `metal-servers` namespace via the pool resource's own `namespace` field.

---

## 4. Approaches

### 4.0 Source model — the decision (both proven viable)

Two of my original blockers against `source.kustomize` were **empirically disproven** this
session:

- **Seed egress is open to GitHub.** A `curl` pod in `shoot--cp--m-qa-de-200` on
  `a-qa-de-200` reached `github.com` (200), `raw.githubusercontent.com` (301), and
  `codeload.github.com` (301) in under a second each. The DDO git resolver clones the
  `?ref=`-pinned tree from inside the seed — so that clone works. (My "same wall as the
  keppel image mirrors" claim was wrong; the image mirrors are a registry allowlist, not a
  blanket internet block.)
- **DDO delivers by direct SSA, not Gardener ManagedResources.** `internal/deliver/applier.go`
  Server-Side-Applies every rendered manifest straight onto a per-cluster client
  (`buildShootApplier()` builds the shoot client from the token-requestor Secret). There is
  no ManagedResource wrapper in the DDO path; the legacy `templates/managedresource.yaml`
  is legacy-only and is dropped. This is post-render and **source-agnostic** (identical for
  Helm and kustomize).

What remained was a genuine trade-off. Kustomize wins on: no helmify, no Helm chart to
publish, direct pinning of the upstream CAPI-IPAM bases, SAP additions expressed as natural
kustomize patches, and the seed/shoot **path** split matching the two renders with no `mode`
flag. Helm would have won on fleet consistency (the 3 prior charts) and reuse of the
`_helpers` additions-stamp + `no-mode-default.sh`/`selector-parity.sh` CI gates. **User chose
kustomize.** ipam will be the lone `source.kustomize` operator in the fleet; that is accepted.

### 4.1 DDO kustomize render contract (verified in operator source)

`kustomizeSource.Render(ctx, mode, namespace)` (`internal/source/kustomize.go`):
- `subPath = (mode == shoot) ? spec.ShootPath : spec.SeedPath`.
- `resolver.Resolve(url, subPath)` git-clones the `?ref=`-pinned root to a temp dir and
  returns `<tmp>/<rootSubPath>/<subPath>`.
- `krusty.MakeKustomizer({LoadRestrictionsNone}).Run(fsOnDisk, root)` → `resMap.AsYaml()`.
- `manifest.Parse(…, OriginUpstream)` then `ApplyNamespace(manifests, namespace)`.
- **No values mechanism.** Per-cluster differences are expressed as committed overlay
  content, not CR values.

`gitResolver` (`internal/source/gitresolver.go`): URL form
`https://host/org/repo//rootSubPath?ref=TAG|BRANCH|SHA`. The `//` separates the in-repo
root path; `?ref=` is **mandatory**. A 7–40-hex SHA → full-depth fetch + checkout; a
tag/branch → `Depth 1` single-branch clone; all fail-closed. Embedded `user:token@` is
rejected — use `authSecretRef` (anonymous works here since helm-charts is public).

### 4.2 Deliverable 1 — the kustomize overlay tree (`helm-charts`, public)

A new tree under `helm-charts` (exact path a builder decision — proposed
`system/ipam-capi-remote-ddo/` for fleet discoverability, containing only kustomize, no
Chart.yaml):

```
system/ipam-capi-remote-ddo/
  base/
    kustomization.yaml        # common resources + common labels/annotations (fullname identities)
    …shared resources…
  seed/
    kustomization.yaml        # resources: ../base (seed subset) + seed-only resources; images: transformer
    deployment.yaml           # controller Deployment + webhook-injector sidecar (r7 args)
    webhook-service.yaml
    webhook-injector-rbac.yaml
    webhook-injector-metrics-service.yaml
    webhook-injector-servicemonitor.yaml
    remote-kubeconfig-secret.yaml      # token-requestor Secret ipam-capi-remote-kubeconfig
    remote-kubeconfig-configmap.yaml
    …patches (podLabels, KUBERNETES_SERVICE_HOST, securityContext)…
  shoot/
    kustomization.yaml        # resources: CRDs + controller RBAC + webhook configs + (optional) pools
    crds/                     # 7 CRDs vendored to match the LIVE v0.21.0 bundle
    rbac.yaml                 # controller RBAC incl. cross-operator metal bindings (verbatim)
    webhooks.yaml             # Mutating + Validating webhook configurations
    pools.yaml                # shape-agnostic GlobalInClusterIPPool template (listed only by overlays of clusters that have pools; NOT referenced for a-qa-de-200)
```

Mode-enablement is **structural**: the `seed/` kustomization lists only seed resources, the
`shoot/` kustomization lists only shoot resources. No `mode` flag, no `if-eq`. A resource
placed in `base/` renders into **both** seed and shoot, so `base/` carries only genuinely
shared config (identity labels/annotations, common metadata) — never a seed-only or
shoot-only object — keeping the two overlays DRY. Because kustomize is static (no
conditional rendering), a pool is delivered only where its overlay's `resources:` list
references `pools.yaml`; the a-qa-de-200 shoot overlay simply omits it.

**CRD sourcing — vendor, not remote-base.** Although the seed *can* reach GitHub, the CRDs
are **vendored** as local files in `shoot/crds/` (hermetic, reproducible, diffable against
the live bundle, and immune to upstream tag retagging). They are produced once by running
the same pinned kustomize bases the legacy tree used (provider `config/crd` +
`config/rbac` @ `ref=v1.1.1` and the 3 core CAPI raw files @ `v1.14.2`) and then committed.
A CI/verification gate diffs them field-for-field against the live `v0.21.0` bundle.

**Images** are set by a kustomize `images:` transformer in each overlay's
`kustomization.yaml` (keppel mirrors), not by CR values.

**SAP additions** (token-requestor Secret, remote-kubeconfig ConfigMap, webhook-injector
sidecar, the 7 Gardener networking podLabels, `KUBERNETES_SERVICE_HOST` + `KUBECONFIG`
wiring, cross-operator RBAC) are overlay resources/patches — the same additions that would
be Helm templates in the rejected approach.

### 4.3 Deliverable 2 — the DDO CR (`kube-secrets`, internal)

A `DualDeploymentOperator` CR (base defaults in
`values/helm/admin-k3s/dual-deployment-operator.yaml` under
`dualDeploymentOperatorCRDefaults.ipam-capi-remote`, plus the `a-qa-de-200` instance in the
overlay), using **`source.kustomize`**:

Base defaults under `dualDeploymentOperatorCRDefaults.ipam-capi-remote`; the per-cluster
instance under `dualDeploymentOperatorCRs.ipam-capi-remote` in the `a-qa-de-200` overlay
(same split the 3 prior CRs use):

```yaml
source:
  kustomize:
    url: https://github.com/sapcc/helm-charts//system/ipam-capi-remote-ddo?ref=<tag-or-branch>
    seedPath: seed
    shootPath: shoot
shootNamespace: kube-system
applyOrder: SeedFirst
shootAccess:
  secretName: dual-deployment-operator-shoot-access
  server: https://api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap  # REQUIRED (per-cluster, in overlay)
transformations:
  # NO rewriteWebhookURL — see note below; it would be a no-op for ipam.
  - patch:                       # MutatingWebhookConfiguration
      target: { kind: MutatingWebhookConfiguration }
      strategicMerge: { metadata: { labels: { dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote } } }
  - patch:                       # ValidatingWebhookConfiguration (PatchSpec.target is a single kind → two patches)
      target: { kind: ValidatingWebhookConfiguration }
      strategicMerge: { metadata: { labels: { dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote } } }
```

> **`shootAccess.server` is required** (`api/v1alpha1/dualdeploymentoperator_types.go:95-104`,
> `MinLength=1`) — it is a per-cluster value set in the overlay instance, not the base
> defaults; all 3 prior CRs set it to the `m-qa-de-200` shoot apiserver endpoint above.
>
> **`rewriteWebhookURL` is dropped.** That transformation
> (`internal/transform/rewrite_webhook_url.go:92-105`) only converts a *service-based*
> `clientConfig` to a url-based one and **returns early if a `url` is already present**. The
> legacy ipam webhook configs already use `clientConfig.url:
> https://ipam-capi-remote-webhook-service:443/…` (all 8 webhooks, both MWC and VWC), so the
> transformation would be a no-op. The correct URL must therefore be present in the rendered
> kustomize output itself — and since the webhook Service name
> (`ipam-capi-remote-webhook-service`) is identical in the seed and shoot renders, the same
> URL is correct for both and **no rewrite is needed**. Only the two injector-target-label
> patches remain.

No `values`/`seedValues`/`shootValues` (kustomize has none). No keppel chart publish. The
per-cluster delta (the `?ref=`, `shootAccess.server`, and anything cluster-specific) lives
in the overlay instance — not as CR values.

### 4.4 Deliverable 3 — cutover profile

`system/dual-deployment-operator/cutover/profiles/ipam-capi-remote.env` for the generalized
toolkit (on branch `feat/ddo-cutover-toolkit`):

```
RELEASE=ipam-capi-remote
DDO_CR=ipam-capi-remote
LEGACY_CHART_DIR=system/ipam-capi-remote
OVERLAY_DIR=system/ipam-capi-remote-ddo        # replaces OPERAND_CHART_DIR (no chart)
ROLLOUT_ORDER=40
DEPLOY=ipam-capi-controller-manager
CONTROLLER_POD_SELECTOR=control-plane=controller-manager,app.kubernetes.io/name=ipam-capi-remote
CRD_GROUPS=ipam.cluster.x-k8s.io               # NOT cluster.x-k8s.io (shared core)
NAMESPACE_CASCADE_GATE=off
PROTECT_MRS=''                                 # nothing to protect (pools out-of-band)
FREEZE_KINDS_NS=globalinclusterippools.ipam.cluster.x-k8s.io
BASELINE_SNAPSHOT_KINDS_NS=globalinclusterippools.ipam.cluster.x-k8s.io
```

---

## 5. Cutover shape

Simplest of the four migrations. The pools are out-of-band and the CRD MRs already carry
`keepObjects: true`, so there is **nothing to protect-then-teardown** (`PROTECT_MRS=''`).
The toolkit still:
- BASELINE-snapshots the 2 pool UIDs and asserts their survival post-cutover.
- Backs up both webhook configurations and the 2 pools before the window.

Outage risk: the webhooks are `failurePolicy: Fail`, so during the brief window between
removing the legacy delivery and DDO applying the webhook configs, **pool writes** could be
rejected. Reads and existing allocations are unaffected, and `qa-de-200` is near-static, so
practical impact is near-zero. The toolkit's `cutover-ddo.sh` governs this with
`OUTAGE_BUDGET_MIN=20` (user-accepted default), exit-code-30 on budget-blown, and an S0–S3
rollback planner driven by pre-uninstall `hs get manifest/values/all` captures. If an abort
lands mid-flight, the backed-up webhook configs + pools are the manual restore artifacts.

---

## 6. Branch / PR hygiene

- One feature branch **`feat/ipam-capi-remote-ddo-m-qa-de-200`** (already created off
  `master`, fresh worktree), one PR per repo.
- helm-charts PR (public, `github.com`): the overlay tree + the cutover profile.
- kube-secrets PR (internal, `github.wdf.sap.corp`, `gh` CLI): the DDO CR values.
- CODEOWNERS entry on the new tree matching the legacy chart's owners.
- **Strict merge order** (publish-before-merge, adapted for kustomize): merge the
  helm-charts PR → **push/tag the `?ref=`** the CR points at so the overlay is resolvable →
  then merge the kube-secrets CR PR → then run the live cutover. (If the CR's `?ref=`
  resolves to an unmerged/absent commit, the seed render fails `SeedRenderFailed` on clone —
  the kustomize analogue of the keppel publish-before-merge gate.)

---

## 7. Verification path

1. **Local render parity.** `kustomize build system/ipam-capi-remote-ddo/seed` and
   `…/shoot` produce exactly the expected seed vs shoot object sets (seed: Deployment +
   sidecar + webhook Service + injector RBAC/metrics/SM + token-requestor Secret +
   remote-kubeconfig ConfigMap; shoot: 7 CRDs + controller RBAC incl. cross-operator
   bindings + both webhook configs + zero pools for a-qa-de-200).
2. **CRD field-diff gate.** Vendored CRDs diff clean (field-for-field) against the live
   `v0.21.0` bundle — including the move-hierarchy label, provider common-label, and
   cert-manager CA-injection annotation.
3. **Shoot-RBAC fidelity gate.** The cross-operator metal bindings and the ipam roles match
   the live cluster exactly (no widening/narrowing).
4. **Webhook render parity.** After the two label patches, both webhook configs carry the
   injector target label and the correct `clientConfig.url` (already present in the rendered
   output — no `rewriteWebhookURL`, see §4.3).
5. **Post-cutover UID preservation.** Both pool UIDs unchanged; allocations intact; DDO CR
   `Ready=True`; seed + shoot resources Healthy.

---

## 8. Left to the builder

- Exact overlay tree path/layout under `helm-charts` (proposed `system/ipam-capi-remote-ddo/`;
  confirm vs a `system/kustomize/`-style location) and how `base/` is split from the two
  overlays.
- Produce the vendored CRDs from the pinned bases and prove the field-diff gate green.
- Confirm `filterKinds` is unnecessary (expected: overlays list only mode-appropriate
  resources, so no post-render kind filtering is needed).
- Confirm `manager-config.yaml` is vestigial (the live Deployment passes `--leader-elect` /
  `--webhook-port` as args and does not mount the ConfigMap) and omit it.
- Verify the webhook-injector keppel mirror
  (`i-cant-believe-its-not-cloud-infrastructure-dev`) is pullable from the seed and pick the
  exact r7 tag.
- Confirm exact live pod/selector labels and whether a NetworkPolicy/Ingress object is part
  of the live set.
- Confirm the two separate webhook label-patch transformations are accepted by the CR schema
  (PatchSpec.target is a single kind selector → two patches).
- Choose the `?ref=` strategy (branch during bring-up, pin to a tag/SHA for the durable CR).
- PR `#13167` sequencing for the cutover toolkit profile (fold into the helm-charts PR vs
  its own, per the prior charts).
