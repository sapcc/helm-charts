# ipam-capi-remote → DDO migration — Design

> **Status:** awaiting approval. FOURTH chart migrated to dual-deployment-operator
> (DDO) after `metal-operator-remote` (live, Ready), `boot-operator-remote` (merged,
> published), and `argora-operator-remote` (live, Ready). Same proven pattern; ipam's
> defining shape is **a webhook + webhook-injector sidecar** — making
> `metal-operator-remote-ddo` (the only prior migration with a webhook) the closest
> reference, **except** ipam has **no upstream Helm chart** so the operand chart
> re-templates in-place instead of wrapping a vendored subchart.
>
> **Scope approved by user (2026-10-30):** thin operand chart
> `system/ipam-capi-remote-ddo` (hand-authored, mode-guarded flat templates, vendored
> CRDs — NO subchart) + DDO CR values in kube-secrets + an ipam profile for the
> generalized cutover toolkit. Architecture decisions confirmed this session:
> (1) keep `source.helm` operand chart (reject CR-only / `source.kustomize`);
> (2) keep the legacy `build-ipam-capi-remote` helmify make target untouched (DDO work
> is purely additive); (3) operand-chart internal layout = mode-guarded flat templates
> with the 4 CRDs authored as `mode=shoot` template files (NOT a Helm `crds/` dir).

---

## 1. Intent & why

Migrate the `ipam-capi-remote` deployment for cluster **m-qa-de-200** from the legacy
Gardener ManagedResource + Helm-release model to **DDO**-managed deployment, rendered
from a new operator-native operand chart `system/ipam-capi-remote-ddo`
(mode=seed / mode=shoot).

> **Topology / terminology (authoritative — SCI Gardener architecture doc).**
> `m-qa-de-200` is the **Metal-API cluster**: a *workerless* shoot that only **stores**
> the CAPI-IPAM custom resources (the `GlobalInClusterIPPool`s) — it has no nodes and
> runs no workload. The ipam **controller runs in the seed** (`a-qa-de-200`, the
> single-node k3s that bundles the full Gardener + Metal-API setup) in namespace
> `shoot--cp--m-qa-de-200`, and reaches the Metal-API cluster via a token-requestor
> kubeconfig. This maps onto DDO's two renders: the **seed render → `a-qa-de-200`**
> (controller Deployment + webhook-injector sidecar, webhook Service, token-requestor
> Secret, remote-kubeconfig ConfigMap, webhook-injector RBAC), the **shoot render →
> `m-qa-de-200`** (the 4 CRDs, controller RBAC incl. the cross-operator metal binding,
> the Mutating/Validating webhook configurations, and the `GlobalInClusterIPPool`
> data CRs). The Metal-API cluster `m-$REGION` is **NOT** the Management cluster
> `mgmt-$REGION`.

**Why:** continue the fleet rollout replacing the pre-render-and-commit / GRM model
with DDO's two-render SSA model, moving per-cluster config into a
`DualDeploymentOperator` CR delivered from `cc/kube-secrets`. ipam shares the seed CP
namespace with the already-migrated metal + boot + argora operators and is the next
slice.

**Why now:** metal + boot + argora are proven on this exact cluster; the DDO controller
is installed and healthy. ipam is the chart that exercises the **webhook split** again
(after metal) but on a chart with **no vendored upstream subchart** — the last real
structural variation before the remaining remote charts are mechanical.

## 2. Goals / non-goals / anti-goals

**Goals**
- A thin `system/ipam-capi-remote-ddo` operand chart DDO renders twice, hand-authored
  with mode-guarded flat templates (no subchart; CRDs vendored as `mode=shoot`
  templates).
- DDO CR values (defaults + a-qa-de-200 instance) added to the existing kube-secrets
  `dualDeploymentOperatorCRs` / `dualDeploymentOperatorCRDefaults` structure.
- An `ipam-capi-remote` profile for the generalized cutover toolkit
  (`system/dual-deployment-operator/cutover/`).
- Preserve the live `GlobalInClusterIPPool` data CRs on `m-qa-de-200` — data + UID
  preserved across re-ownership. Two pools are live:
  `globalinclusterippool-mgmt-qa-de-200`
  (UID `83614ed7-f367-4bd0-acdd-4fbd4de76eec`, `10.219.139.128/26`, **1 address
  already allocated**) and `test` (UID `d7d99994-c27d-4116-835b-4d858069b7ea`, 0 used).
- The webhook split handled exactly as metal does it: `rewriteWebhookURL` +
  webhook-injector sidecar, with the webhook-config label patch applied to **both** the
  Mutating and Validating webhook configurations.

**Non-goals**
- Migrating any other remote chart, or ipam on any cluster other than m-qa-de-200.
- Changing the legacy `build-ipam-capi-remote` helmify make target or the legacy
  `system/ipam-capi-remote` chart (both stay; DDO work is additive).
- Touching legacy GRM consumers on other clusters (they keep the legacy chart).
- Upgrading the CAPI-IPAM controller version as part of this migration (stays `v1.1.1`).

**Anti-goals**
- Breaking the legacy `ipam-capi-remote` chart for non-DDO clusters.
- An immutable-selector collision leaving two controllers churning.
- Loss/recreation of the live `GlobalInClusterIPPool` data (the allocated address in
  `globalinclusterippool-mgmt-qa-de-200` must survive with the same UID).
- A webhook that points at the wrong service after the split (CREATE/UPDATE on pool
  kinds fails closed, `failurePolicy: Fail`) — the `rewriteWebhookURL` + label-patch
  must land on both webhook configs.
- Dropping the **cross-operator RBAC** that lets `metal-operator-controller-manager`
  act on ipam `ipaddressclaims` (breaks metal↔ipam integration).

## 3. Constraints (cluster-authoritative unless noted)

- **ipam HAS a webhook + webhook-injector sidecar** (unlike boot/argora; like metal).
  → the seed render carries the webhook-injector initContainer, the webhook Service,
  and the webhook-injector RBAC/metrics/servicemonitor; the shoot render carries the
  Mutating + Validating webhook configurations; a `rewriteWebhookURL` transformation
  rewrites the webhook `clientConfig.url` for the split; a `patch` transformation
  stamps the `dual-deployment-operator.cc.sap/webhook-injector` target label on **both**
  webhook configs (metal patches only its single VWC — ipam has a MWC **and** a VWC).
- **NO upstream Helm chart** for `kubernetes-sigs/cluster-api-ipam-provider-in-cluster`
  (clusterctl / kustomize only — perplexity-confirmed). → the operand chart has **no
  `dependencies:` / no vendored subchart**. It carries its OWN Deployment, webhook
  Service + sidecar, RBAC, the 4 CRDs, and the data-CR template, each a hand-authored
  template guarded by `{{- if eq .Values.mode "seed" | "shoot" }}`. This is the one
  structural divergence from metal/boot/argora (which key subchart flags under an alias
  like `metal-operator-core:` and drive modes via `seedValues`/`shootValues` maps).
  ipam instead drives modes via the chart's own guards + top-level flags.
- **Legacy chart is helmify-generated and STAYS.** `build-ipam-capi-remote`
  (system/Makefile L87-106: `kubectl kustomize | helmify -crd-dir ipam-capi-remote`
  then ~15 sed/yq fixups) consumes `kustomize/ipam-capi-remote/` and is listed in the
  `build:` aggregate. The DDO operand chart is **separate and fully hand-authored**
  (confirmed: NO `build-*-ddo` targets exist for metal/boot/argora/ipam) → the
  migration adds files only; no Makefile edits/deletions.
- **CRD source (Option B — "regenerate carefully", user-chosen).** The live
  `crds-rbac.yaml` bundle carries `controller-gen.kubebuilder.io/version: v0.21.0`, but
  upstream `v1.1.1` (`config/crd/bases`, commit `7933583138cf…`) was generated with
  `controller-gen v0.17.2`. **→ the live CRDs were SAP-regenerated with a newer
  controller-gen, NOT vendored upstream verbatim.** So the operand chart must vendor
  CRDs that match the **LIVE v0.21.0 bundle** field-for-field, not raw upstream
  `v0.17.2` output, or risk a cosmetic/field diff on the live pools (which could churn
  the CRD on apply). The 4 pool CRDs are: `InClusterIPPool`, `GlobalInClusterIPPool`
  (both serve v1alpha1 `storage:false` + v1alpha2 `storage:true`), `InClusterPrefixPool`,
  `GlobalInClusterPrefixPool` (both v1alpha2 only, storage). `IPAddress`/`IPAddressClaim`
  are **CAPI core** CRDs (`sigs.k8s.io/cluster-api v1.14.0`), not provider CRDs — the
  live bundle vendors them too (as `mr-crd-ipaddresses-…`, `mr-crd-ipaddressclaims-…`);
  reproduce whatever the live bundle ships. The live bundle also includes
  `mr-crd-clusters-cluster-x-k8s-io` (group `cluster.x-k8s.io`) — 7 CRD MRs total.
- **CRD provider labels/annotations (reproduce from live).** Upstream stamps
  `clusterctl.cluster.x-k8s.io/move-hierarchy: ""` as a **label** (not annotation) via
  `config/crd/patches/clusterctl-label_*.yaml`, `cluster.x-k8s.io/provider:
  ipam-in-cluster` via `config/default` commonLabels, and a cert-manager CA-injection
  annotation on the `InClusterIPPool` + `GlobalInClusterIPPool` CRDs via
  `webhookcainjection_patch.yaml`. The builder reproduces **exactly what the live
  bundle carries** (diff-driven), since the live bundle is the UID-preservation
  authority — not what a fresh kustomize build emits.
- **Staying updated with upstream (documented policy, user-raised).** No `helm dep up`
  path exists (no upstream chart). The CRDs are the provider's public API and change
  far less often than the image. Policy baked into the chart README: image bumps happen
  entirely in the kube-secrets CR (no chart change); on an upstream version bump, diff
  only `config/crd/bases/*`, the RBAC manifests, and the Deployment/controller config;
  re-vendor CRDs **only if** `spec.versions` / `openAPIV3Schema` / printer columns /
  conversion changed; always eyeball RBAC + Deployment even when the CRD diff is empty.
- **Cross-operator RBAC (must preserve — cluster-authoritative).** The legacy
  `managedresources/rbac.yaml` binds **both** `ipam-capi-controller-manager` **and**
  `metal-operator-controller-manager` (kube-system) to ipam roles —
  `ipam-capi-metal-rolebinding` / `ipam-capi-metal-admin-rolebinding` give
  metal-operator the ipam `manager-role`/`admin-role` (ipaddressclaims
  get/list/patch/update/watch/create/delete). The `mode=shoot` RBAC templates MUST
  reproduce these cross-operator bindings, or metal↔ipam integration breaks.
- **Data CRs** (`GlobalInClusterIPPool`, group `ipam.cluster.x-k8s.io/v1alpha2`) live on
  the Metal-API cluster `m-qa-de-200` = the DDO "shoot" render target, **in namespace
  `metal-servers`** (NOT kube-system — distinct from argora/boot). → authored as a
  **mode=shoot addition template** driven by CR `values.pools`, namespace `metal-servers`,
  mirroring the legacy `managedresources/globalinclusterippool.yaml` (ranges
  `.Values.pools`, fields `addresses`/`excludedAddresses`/`prefix`/`gateway`). The
  template MUST be **shape-agnostic** (`range` the pools map, `toYaml` the value
  verbatim) — not a hard-coded spec — so prod regions with richer pool definitions
  migrate later unchanged. (NB the legacy template has a duplicate `spec:` typo line —
  do NOT reproduce the typo.)
- **⚠ The live data CRs are NOT chart-delivered (cluster-authoritative).** Both live
  `GlobalInClusterIPPool`s on m-qa-de-200 have **no MR-origin annotation and no labels**
  → they were created out-of-band, not by the legacy chart. The a-qa-de-200 overlay
  (`values/helm/admin-k3s/qa-de-1/a-qa-de-200/ipam-capi-remote.yaml`) sets **only**
  `controllerManager.manager.env.kubernetesServiceHost` and **no `pools:` key** → the
  legacy chart emits **NO** `GlobalInClusterIPPool` and **NO** pool data-CR MR. **→
  there is NOTHING to protect-then-teardown** (no `mr-gicp-*` MR exists); a `helm
  uninstall` of `ipam-capi-remote` cannot delete the pools because it never owned them.
  The cutover must still **BASELINE-snapshot the 2 live pool UIDs and assert survival**
  post-cutover (do-no-harm), but there is no `PROTECT_MRS` data-CR entry.
  - **⚠ Design decision for the DDO a-qa-de-200 CR:** because the live pools are
    out-of-band and the legacy overlay sets no `pools`, the DDO CR for a-qa-de-200 must
    **also set no `pools`** (empty), so the shoot render emits no `GlobalInClusterIPPool`
    and DDO does **not** try to adopt/own the 2 live out-of-band pools (which would
    change their ownership/UID semantics). The data-CR template still ships in the chart
    (shape-agnostic, for future clusters that DO declare pools via CR values), but is
    inert on a-qa-de-200. Confirm with render: `--set mode=shoot` with no `pools`
    produces zero `GlobalInClusterIPPool` objects.
- **CRD keepObjects:** the 7 legacy CRD MRs (`mr-crd-*`) ALL have `keepObjects: true`
  and are labeled `ipam-capi-remote-webhook-injector: "true"` → uninstall preserves the
  CRD **schemas** (and therefore the pool data stored against them). This is already
  correct — no CRD protect step needed.
- **Seed controller requirements belong in the OPERAND chart values.yaml, NOT the CR**
  (the recurring fleet lesson): the token-requestor Secret (`ipam-capi-remote-kubeconfig`)
  + its Deployment mount, the 7 Gardener networking podLabels, `KUBERNETES_SERVICE_HOST`,
  and `KUBECONFIG` are all static seed-controller wiring. They live in the operand chart
  `controllerManager` block; the CR carries only per-cluster diff. **Zero vault refs in
  the CR** (admin-k3s secrets-injector-validator forbids vault refs in non-Secret kinds)
  — and ipam has no vault creds anyway (no macdb/netbox), so this is naturally satisfied.
- **webhook-injector sidecar r7 port (exact).** Legacy
  `_webhook-injector-sidecar.tpl` uses the pre-r7 arg set
  (`--webhook-config-name`, `--managed-resource-label`, `--external-host/-port`) and has
  a securityContext bug (`.Values.controllerManager.manager.podSecurityContext`). Port to
  metal's r7 form: **DROP** `--webhook-config-name` / `--managed-resource-label` /
  `--external-host` / `--external-port`; **ADD**
  `--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote`;
  **KEEP** `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig` (injector watches
  the SHOOT), `--leader-election-id=ipam-capi-remote-webhook-injector-leader`,
  `--cert-secret-name=ipam-capi-remote-cert-secret`,
  `--cert-sans=ipam-capi-remote-webhook-service`, `--rotation-overlap-window=30s`,
  `--rotation-gate-timeout=30s`; **FIX** securityContext to
  `.Values.controllerManager.podSecurityContext`; pin the image from
  `.Values.webhookInjector` (not `:latest`). Ports metrics 8082 / health 8083; mounts
  `webhook-certs`→`/tmp/webhook-certs`, `remote-serviceaccount`, `remote-kubeconfig`.
- **Images: upstream default in the public chart, keppel mirror override in
  kube-secrets.** Controller default `registry.k8s.io/capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`;
  kube-secrets CR overrides to the live keppel gcr-mirror
  `keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`.
  webhook-injector default `ghcr.io/sap-cloud-infrastructure/webhook-injector` (pin
  metal's r7 tag `sha-f85df8e3d55165e3b6e1117f6b120624268d0976` for the target-patch
  flags); kube-secrets CR overrides repository to metal's **verified-pullable** mirror
  `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector`
  (NOT the `cloud-infrastructure-dev` path the legacy ipam region overlay used — metal's
  base-defaults comment warns that path lacks these tags), tag per-cluster overlay.
- **Chart version must be clean semver** (metal lesson: `_sha` suffix → "improper
  constraint" → SeedRenderFailed). Start `0.1.0`, bump patch per change.
- **`charts/*.tgz` is gitignored** (root `.gitignore` `*.tgz`) — n/a here (no subchart)
  but Chart.lock is also n/a (no dependencies). Nothing to vendor/lock.
- **Naming / identity (⚠ load-bearing).** `fullnameOverride: ipam-capi` (matching the
  legacy chart) so every object renders with the live legacy identity. The live seed
  Deployment is `ipam-capi-controller-manager`; the shoot SA is
  `ipam-capi-controller-manager` @ kube-system; the webhook-injector SA/Service use
  `ipam-capi-remote-webhook-injector` / `ipam-capi-remote-webhook-service`; the webhook
  configs are `ipam-capi-remote-{mutating,validating}-webhook-configuration`. The
  token-requestor kubeconfig is minted for SA `ipam-capi-controller-manager` @
  kube-system. **Validated by render** (helm template seed+shoot). The sidecar
  `--target-label` value and the CR `patch` label value must match the webhook-injector
  identity `ipam-capi-remote`.
- **Selector parity.** Live seed Deployment selector: `control-plane: controller-manager`
  + the chart's `app.kubernetes.io/{name,instance}` selector labels. The webhook Service
  selector matches the manager pod (`control-plane: controller-manager` +
  `app.kubernetes.io/name=ipam-capi-remote` + instance). The DDO seed render must
  reproduce these; `ci/selector-parity.sh` asserts it.
- **Shared namespace** — ~9+ releases share shoot--cp--m-qa-de-200. Teardown ownership
  by `meta.helm.sh/release-name` annotation, NEVER a name prefix.

## 4. Approaches considered

### 4a. The operand chart shape

**Decided (Approach 1 — mode-guarded flat templates).** Every object is a
hand-authored template in `templates/` wrapped `{{- if eq .Values.mode "seed" }}` or
`"shoot"`. Rejected alternatives:
- **Helm `crds/` dir for the 4 CRDs** — rejected: DDO renders via `helm template`,
  which **ignores `crds/` entirely**, so the CRDs would never be delivered (hard DDO
  constraint). CRDs must be `mode=shoot`-guarded template files.
- **Two subcharts (seed/shoot)** — rejected as over-engineered vs the flat-template
  pattern the fleet already uses.
- **Vendoring an upstream subchart** — impossible (no upstream chart exists).

Authoring the CRDs as templates also keeps the `rewriteWebhookURL` / `filterKinds`
transformations and the `chart.additionsAnnotations` origin stamp applying uniformly
across the whole render.

```
system/ipam-capi-remote-ddo/
  Chart.yaml            # type application, NO dependencies, version 0.1.0
  values.yaml           # fullnameOverride=ipam-capi; NO mode default;
                        #   controllerManager (seed wiring: image, env, 7 podLabels,
                        #   token-requestor mount); webhookInjector (ghcr default + r7 tag);
                        #   webhook.enable; pools: {} (shape-agnostic data-CR source)
  templates/
    _helpers.tpl                      # COPY metal verbatim, rename chart → ipam-capi-remote:
                                      #   dual.seed/dual.shoot guards, chart.{name,fullname,
                                      #   chart,labels,selectorLabels}, chart.additionsAnnotations
    _webhook-injector-sidecar.tpl     # r7 port (see §3)
    controller-manager.yaml           # (mode=seed) Deployment + sidecar initContainer
    webhook-service.yaml              # (mode=seed) Service ipam-capi-remote-webhook-service 443→9443
    webhook-injector-rbac.yaml        # (mode=seed) SA/Role/RB/CR/CRB ipam-capi-remote-webhook-injector
    webhook-injector-metrics-service.yaml   # (mode=seed)
    webhook-injector-servicemonitor.yaml     # (mode=seed)
    remote-kubeconfig.yaml            # (mode=seed) token-requestor Secret ipam-capi-remote-kubeconfig
    remote-kubeconfig-configmap.yaml  # (mode=seed) ConfigMap ipam-capi-remote-kubeconfig
    crds.yaml (or crd-*.yaml)         # (mode=shoot) the 4 (+core?) CRDs, matching live v0.21.0 bundle
    rbac.yaml                         # (mode=shoot) controller RBAC incl. cross-operator metal binding
    webhooks.yaml                     # (mode=shoot) Mutating + Validating webhook configurations
    data-crs.yaml                     # (mode=shoot) GlobalInClusterIPPool, shape-agnostic, ns metal-servers
    [manager-config.yaml]             # ConfigMap -manager-config (leaderElection resourceName) — mode? see §8
  ci/
    no-mode-default.sh  # copy from metal: asserts values.yaml has no `mode`
    selector-parity.sh  # copy/adapt from metal
  README.md             # role, no-subchart rationale, upstream-update policy (§3), render parity
  CODEOWNERS entry      # match legacy /system/ipam-capi-remote owners
```

**Per-mode enablement** is via the chart's own `mode` guards (Approach A for the whole
chart, since there is no subchart whose flags to toggle). The CR's
`seedValues`/`shootValues` therefore carry **chart-level flags** the templates read
(e.g. `webhook.enable`), not subchart-alias maps — the builder confirms the exact flag
names by render. Seed set: controller Deployment + sidecar, webhook Service,
webhook-injector RBAC/metrics/servicemonitor, token-requestor Secret +
remote-kubeconfig ConfigMap. Shoot set: 4 CRDs, controller RBAC (incl. cross-operator
metal binding), Mutating + Validating webhook configs, data-CRs (inert on a-qa-de-200).

### 4b. kube-secrets CR delivery

**No new pipeline.** The CR is delivered by the already-wired `dual-deployment-operator`
release (admin-k3s pipeline → shoot--cp--m-qa-de-200). ipam becomes a fourth entry
alongside metal + boot + argora in the same two files:
- `values/helm/admin-k3s/dual-deployment-operator.yaml` →
  `dualDeploymentOperatorCRDefaults.ipam-capi-remote` (shootNamespace **kube-system** —
  where the ipam SA lives; applyOrder SeedFirst; source repo/name
  `ipam-capi-remote-ddo`; keppel image overrides for controller + webhook-injector;
  seed/shootValues chart flags; the `rewriteWebhookURL` + dual-webhook-config label
  `patch` transformations).
- `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` →
  `dualDeploymentOperatorCRs.ipam-capi-remote` (per-cluster diff: enabled,
  source.version, shootAccess.server, KUBERNETES_SERVICE_HOST
  `api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap`,
  global.region/clusterType, webhook-injector tag; **no `pools`** — see §3).

**shootNamespace:** `kube-system` (the ipam SA `ipam-capi-controller-manager` and the
RBAC live there; the data pools go to `metal-servers` via the data-CR template's own
`namespace:` field, independent of shootNamespace). **Transformations:**
- `rewriteWebhookURL { urlPrefix: https://ipam-capi-remote-webhook-service:443 }` —
  rewrites the webhook `clientConfig.url` for the split (copy metal's shape).
- `patch` on the **MutatingWebhookConfiguration** AND `patch` on the
  **ValidatingWebhookConfiguration** (two patch transformations, or one per kind —
  metal uses one for its single VWC), strategicMerge
  `metadata.labels.dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote`
  so the webhook-injector `--target-label` matches both configs.
- **`filterKinds`?** — the builder confirms by render whether any upstream Secret/Service
  must be pruned from the shoot (metal/boot/argora each needed one; ipam re-templates
  in-place so it may not emit a stray upstream Secret, but the webhook-injector metrics
  Service and token Secret must stay **seed-only**, which the `mode=seed` guards already
  enforce — so a `filterKinds` may be unnecessary). Decide by diffing the shoot render.

> **Dependency (flagged to user):** SCI #1542 may relocate ALL DDO CR delivery into a
> dedicated chart fleet-wide. Proceed with the existing `dualDeploymentOperatorCRs`
> pattern now; if #1542 lands, ipam's CR migrates with the fleet. Not a blocker.

### 4c. Cutover tooling

Reuse the generalized toolkit (`system/dual-deployment-operator/cutover/`, shipped via
the argora-era PR #13167). Add `profiles/ipam-capi-remote.env`:
- `RELEASE=ipam-capi-remote`, `DDO_CR=ipam-capi-remote`,
  `LEGACY_CHART_DIR=system/ipam-capi-remote`,
  `OPERAND_CHART_DIR=system/ipam-capi-remote-ddo`, `ROLLOUT_ORDER=40` (after argora's 30).
- `DEPLOY=ipam-capi-controller-manager` (live-confirmed name).
- `CONTROLLER_POD_SELECTOR="control-plane=controller-manager,app.kubernetes.io/name=ipam-capi-remote"`
  (builder confirms the exact live pod labels).
- `CRD_GROUPS="ipam.cluster.x-k8s.io"` (the pool kinds; `cluster.x-k8s.io` core CRDs are
  shared with CAPI and NOT ipam-owned — do not teardown-gate on them).
- `NAMESPACE_CASCADE_GATE="off"` (ipam owns no namespace).
- `PROTECT_MRS=""` — **none.** The live pools are out-of-band (not chart-delivered), so
  no data-CR MR exists to protect (§3).
- `FREEZE_KINDS_NS="globalinclusterippools.ipam.cluster.x-k8s.io"` — assert no pool is
  Terminating before teardown.
- `BASELINE_SNAPSHOT_KINDS_NS="globalinclusterippools.ipam.cluster.x-k8s.io"` — snapshot
  the 2 live pool UIDs + specs pre-uninstall so verify asserts data + UID preserved.
- `VERIFY_SAMPLE=""` — the do-no-harm invariant is pool-data/UID preservation, covered
  by the baseline snapshot.

> **Dependency:** the cutover toolkit (PR #13167) must be on master (or its branch
> merged) before the live cutover runs. The ipam cutover profile can ship in the ipam
> helm-charts PR or fold into a combined profiles PR per user preference.

## 5. The cutover shape

Same coordinated single-window cutover as the prior three, **simpler than metal/argora**
because there is nothing to protect (no chart-owned data-CR MR; CRD MRs already
`keepObjects:true`):
```
baseline-snapshot the 2 live pools (UID+spec) → freeze-check (no pool Terminating)
  → uninstall ipam-capi-remote  (CRD schemas survive via keepObjects; pools are
      out-of-band so untouched)
  → (merge DDO CR PR, reconcile) → DDO renders seed+shoot, applies via SSA
  → verify: DDO CR Ready; controller Deployment DDO-owned 1/1; webhook-injector sidecar
      up; 4 CRDs present (UID unchanged); Mutating+Validating webhook configs point at
      ipam-capi-remote-webhook-service and carry the target label; 2 live pools still
      present, same UID, allocation intact
```
ipam specifics:
- **No protect-then-teardown step** (the data CRs are out-of-band; the CRD MRs already
  keepObjects). This is the simplest cutover of the four.
- **Webhook continuity is the risk, not data.** During the window between uninstall and
  DDO apply, the Mutating/Validating webhook configs (`failurePolicy: Fail`) could block
  CREATE/UPDATE/DELETE on the 4 pool kinds. Pool **reads and existing IP allocations are
  unaffected** — only writes are briefly blocked, and on qa-de-200 the pools are
  near-static (1 pool / 1 allocation, 1 empty `test` pool), so real-world impact is
  near-zero.
- **Outage budget + rollback are already formalized by the cutover toolkit** (branch
  `feat/ddo-cutover-toolkit`), and ipam adopts the defaults (user decision 2026-10-30:
  *"Keep default 20-min budget"*). `cutover-ddo.sh` runs with `OUTAGE_BUDGET_MIN=20`:
  it captures rollback material **before** uninstall (`hs get manifest > rollback-manifest.yaml`,
  `hs get values > rollback-values.yaml`, `hs get all > rollback-info.txt` in the state dir),
  stamps the uninstall epoch, and if the new deployment is not healthy within the budget
  exits **30** ("Outage budget blown — rollback required") into the S0–S3 rollback planner
  (S0 state-unreadable / S1 clean-uninstall → reinstall from `rollback-manifest.yaml` /
  S2 partial → careful choreography / S3 new-deployment-healthy → proceed). No ipam-specific
  rollback logic is needed; the profile just sets the budget and the runbook references the
  exit-30 path. The runbook must still sequence uninstall→reconcile tightly and verify the
  webhook endpoints resolve post-apply before declaring done.
- **Back up** the 2 live pools + the Mutating/Validating webhook configs before the window
  (standing "back up before live change" directive). The backed-up webhook configs are the
  manual restore artifact if an abort lands in S2 before DDO re-applies them.

## 6. Branch / PR hygiene

- ONE feature branch off `master` → ONE PR per repo (user preference; no stacked PRs).
  Proposed branch: `feat/ipam-capi-remote-ddo-m-qa-de-200`. **Create a fresh worktree**
  (current cwd is the argora worktree).
- Two repos → two PRs: helm-charts (public, `GH_HOST=github.com`): operand chart
  (+ cutover profile, unless folded); kube-secrets (internal,
  `GH_HOST=github.wdf.sap.corp`, `gh` CLI — MCP github tools CANNOT reach it): CR values.
- **CODEOWNERS:** add `/system/ipam-capi-remote-ddo` matching the LEGACY
  `/system/ipam-capi-remote` owners (builder reads the live CODEOWNERS entry; a reviewer
  required this for the prior charts).
- **Publish precondition** (the lesson that broke boot): the operand chart version MUST
  be published to keppel BEFORE the kube-secrets CR referencing it merges (else
  SeedRenderFailed). Verify:
  `helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/ipam-capi-remote-ddo --version 0.1.0`.
- **Merge order (strict):** helm-charts operand-chart PR merges → publish operand chart
  to keppel + verify → THEN kube-secrets CR PR merges → THEN live cutover (toolkit on
  master).

## 7. Verification path (cluster-authoritative)

- `helm template --set mode=seed` and `--set mode=shoot` render clean (no subchart →
  no `helm dependency build`).
  - **seed**: controller Deployment `ipam-capi-controller-manager` (selector
    `control-plane: controller-manager` + chart selector labels; 7 Gardener networking
    podLabels; manager container `…:v1.1.1`; webhook-injector initContainer with the r7
    args + `--target-label=…=ipam-capi-remote`; mounts webhook-certs emptyDir +
    remote-serviceaccount Secret `ipam-capi-remote-kubeconfig` {token→token,
    bundle.crt→ca.crt} + remote-kubeconfig ConfigMap); webhook Service
    `ipam-capi-remote-webhook-service` 443→9443; webhook-injector SA/RBAC/metrics/SM;
    token-requestor Secret + ConfigMap. **No CRDs, no webhook configs, no data-CRs.**
  - **shoot**: the 4 (+core, per live bundle) CRDs; SA `ipam-capi-controller-manager` +
    the ipam ClusterRoles/bindings + **the cross-operator metal bindings**
    (`ipam-capi-metal-rolebinding` / `-admin-rolebinding`); the Mutating + Validating
    webhook configs (post-transformation: clientConfig.url rewritten to
    `https://ipam-capi-remote-webhook-service:443/…`, carrying the target label); **no**
    `GlobalInClusterIPPool` (no `pools` set); **no** controller Deployment / sidecar /
    webhook Service.
- **CRD field-diff vs the live v0.21.0 bundle** (Task gate): render the `mode=shoot`
  CRDs and diff kind+name+`spec.versions`+`openAPIV3Schema`+printerColumns+labels/
  annotations against the live `crds-rbac.yaml` — MUST be semantically identical
  (Option B acceptance gate). Document any intentional deviation in the README.
- **Shoot-RBAC fidelity vs legacy** (Task gate): diff the full object list (kind + name
  + rules) against legacy `managedresources/{crds-rbac.yaml,rbac.yaml}`, confirming the
  cross-operator metal bindings are present. Document deviations in the README.
- **Webhook render parity:** the 2 webhook configs render with all 4 pool kinds each
  (mutating: CREATE/UPDATE; validating: CREATE/UPDATE/DELETE), `failurePolicy: Fail`,
  `ipam.cluster.x-k8s.io/v1alpha2`, and post-transformation point at
  `ipam-capi-remote-webhook-service:443`.
- Image pullability verified on-cluster (keppel refs) — already live, low risk.
- Post-cutover: DDO CR `ipam-capi-remote` Ready=True; controller Deployment recreated,
  DDO-owned, 1/1 with the sidecar up; 4 CRDs owned-by stamped, UID unchanged vs
  baseline; webhook configs point at the right service + carry the target label; the 2
  live pools Ready/present, same UID, allocation intact.
- **Pool-preservation acceptance check (manual):** after cutover, manually diff the 2
  live pools (name, UID, `.spec`, allocation) against the pre-uninstall baseline
  snapshot. Manual acceptance gate in the runbook.
- Dry-run `cutover-ddo.sh --operator ipam-capi-remote --phase uninstall --dry-run`
  passes all read-only gates.
- CI `no-mode-default.sh` + `selector-parity.sh` pass.

## 8. Left to the builder

- **Exact chart-level flag names for mode enablement.** Since there is no subchart, the
  `seedValues`/`shootValues` in the CR toggle chart-level flags the templates read
  (e.g. `webhook.enable`, and whatever gates CRDs/RBAC/Deployment). The builder defines
  these flags in `values.yaml` (all OFF/mode-appropriate by default) and confirms the
  CR `seedValues`/`shootValues` drive them — mirroring how boot/argora split
  controller-vs-crd/rbac, but keyed at chart top-level not under an alias. Render-verify
  seed emits the Deployment+webhook-Service and shoot emits CRDs+RBAC+webhook-configs.
- **CRD regeneration (Option B, "carefully").** Vendor the 4 pool CRDs (+ the core/
  cluster CRDs the live bundle ships) matching the **live v0.21.0 bundle** field-for-
  field — NOT raw upstream v0.17.2 output. Start from the live `crds-rbac.yaml` CRD
  stanzas as the authority; cross-check against upstream `config/crd/bases` at tag
  `v1.1.1` (commit `7933583138cf…`) for schema correctness; reproduce the live
  labels/annotations (`clusterctl.cluster.x-k8s.io/move-hierarchy` label,
  `cluster.x-k8s.io/provider` label, cert-manager CA-injection annotation where live).
  Diff gate in §7.
- **`filterKinds` necessity:** confirm by shoot-render diff whether any upstream
  Secret/Service leaks into the shoot that must be pruned (likely not, since the chart
  is hand-authored with mode guards — unlike the subchart-wrapping prior three). If the
  seed-only objects are already guarded `mode=seed`, omit `filterKinds`.
- **`manager-config.yaml` ConfigMap:** the legacy chart ships a `-manager-config`
  ConfigMap (controllerManagerConfigYaml, leaderElection resourceName
  `7bb7acb4.ipam.cluster.x-k8s.io`). Confirm whether the v1.1.1 controller still
  consumes a mounted config file or takes flags only (legacy Deployment passes
  `--leader-elect=false --webhook-port=9443` as args and does NOT mount the ConfigMap —
  suggesting the ConfigMap is vestigial). Decide by render parity vs the live Deployment;
  likely drop, but verify the controller doesn't read `/controller_manager_config.yaml`.
- **webhook-injector mirror confirmation:** verify metal's
  `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector`
  has the r7 target-patch tag pullable on-cluster before pinning it in the CR (the
  legacy ipam overlay used the different `cloud-infrastructure-dev` path — do NOT reuse
  that one).
- **Exact live pod/selector labels** for `CONTROLLER_POD_SELECTOR` and
  `selector-parity.sh` — read from the live Deployment.
- **`networkpolicy.yaml` / `ingress.yaml`:** confirm against the rendered legacy
  manifest whether the legacy chart ships either (recon saw a `network-policy.yaml`
  template). If the legacy render includes a NetworkPolicy, reproduce it as a `mode=seed`
  addition; ipam has no ingress.
- **Exact chart version** (start 0.1.0) and keppel publish/CI mechanics.
- **PR #13167 / cutover-toolkit sequencing** — confirm the toolkit is on master or fold
  the ipam profile per user preference.
- **Two patch transformations vs one:** confirm whether the DDO `patch` transformation
  targets by `kind` only (then one patch can't hit both MWC+VWC) or supports a list —
  from `api/v1alpha1` PatchSpec.target is a single Selector, so **two** patch
  transformations are needed (one per webhook-config kind). Verify against the DDO
  types.
