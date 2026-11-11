# metal-maintenance-operator-remote → DDO migration — Design

> **Status:** awaiting approval. Successor to the `metal-operator-remote`,
> `boot-operator-remote`, `argora-operator-remote` (all live) and `disco` /
> `ipam-capi-remote` (in flight) migrations on a-qa-de-200. This is the next slice
> in the fleet rollout that replaces the pre-render-and-commit / Gardener
> ManagedResource (GRM) model with DDO's two-render SSA model.
>
> **Scope approved by user (2026-11-11):** Approach A — a thin HELM operand chart
> `system/metal-maintenance-operator-remote-ddo` depending on the upstream
> `metal-maintenance-operator` subchart (alias `mmo-core`, `0.1.0`), all upstream
> flags OFF by default, SAP-added templates, DDO two-render, per-cluster values in a
> kube-secrets CR, **webhook-less** (matching current live behavior). Approaches B
> (kustomize overlay) and C (webhook-dormant-but-wired) were rejected.

---

## 1. Intent & why

Migrate the `metal-maintenance-operator-remote` (MMO) deployment on cluster
**m-qa-de-200** (seed **a-qa-de-200**, namespace **shoot--cp--m-qa-de-200**) from the
legacy Gardener ManagedResource + Helm-release model to
**dual-deployment-operator (DDO)**-managed deployment, rendered from a new
operator-native operand chart `system/metal-maintenance-operator-remote-ddo`
(mode=seed / mode=shoot).

**Why:** continue the fleet rollout that replaces the GRM model with DDO's two-render
SSA model, moving per-cluster config into a `DualDeploymentOperator` CR delivered from
`cc/kube-secrets`. MMO shares the seed CP namespace with the already-migrated
metal-operator and boot-operator, and it is an ironcore-dev chart with a published
upstream Helm chart — so the proven Helm-operand pattern (metal/boot/argora/disco)
applies directly.

**Why now:** metal-operator-remote, boot-operator-remote and argora-operator-remote
are live and `Ready=True` on this cluster; the DDO controller is installed and healthy.
The pattern is proven on four charts. MMO exercises it on a chart whose upstream ships
a **single chart with per-component `enable` flags** (CRDs gated by `crd.enable`, not a
separate `-crds` variant) — a small new shape worth validating, plus it carries the
most **SAP cross-operator RBAC** (token-rotate, OIDC-IAS bindings) of any migration so
far.

## 2. Goals / non-goals / anti-goals

**Goals**
- A thin `system/metal-maintenance-operator-remote-ddo` operand chart that DDO renders
  twice (mode=seed → controller Deployment + seed additions; mode=shoot → CRDs + RBAC).
- DDO CR values (defaults + per-cluster instance) added to the existing kube-secrets
  `dualDeploymentOperatorCRDefaults` / `dualDeploymentOperatorCRs` structure.
- A **cutover profile** for MMO added to the existing generalized cutover toolkit
  (`system/dual-deployment-operator/cutover/profiles/`, branch `feat/ddo-cutover-toolkit`).
- **Behavior parity with today's live deployment**: webhook-less; telemetry-events
  Service present seed-side; the full cross-operator RBAC (token-rotate SA/roles, viewer
  ClusterRole, OIDC-IAS region-templated bindings) preserved on the shoot.

**Non-goals**
- Migrating any other remote chart (metaldhcp, metal-onboarding, khalkeon, …) — each is
  its own future slice.
- Migrating MMO on any cluster other than m-qa-de-200.
- Changing the upstream `metal-maintenance-operator` subchart or its pinned version
  (`0.1.0`).
- Adopting the upstream admission webhook (the chart ships one at 0.1.0, but live runs
  webhook-less; adopting it is a separate future decision — see §3).
- Touching legacy GRM consumers of `metal-maintenance-operator-remote` on other clusters.

**Anti-goals (would make this a failure even if it "works")**
- Breaking the legacy `metal-maintenance-operator-remote` chart for non-DDO clusters.
- An immutable-selector collision that leaves two controllers churning.
- **Dropping any cross-operator RBAC grant** — losing the token-rotate role set or the
  OIDC-IAS developer-group bindings would silently break token rotation or human access.
- Enabling the webhook (new behavior) as a side effect of migrating delivery.
- Orphaning or cascade-deleting the `metal-maintenance-operator-system` /
  `metal-maintenance-sanitization` namespaces or their contents during cutover.

## 3. Constraints (cluster-authoritative unless noted)

- **MMO runs WEBHOOK-LESS today (load-bearing parity).** The upstream `0.1.0` chart
  ships a `ValidatingWebhookConfiguration` (4 webhooks on bios/bmc settings) +
  webhook-service, but both default OFF (`webhook.enable=false`, `certManager.enable=false`),
  master's two values files don't override them, the per-cluster env sets
  `ENABLE_WEBHOOKS='false'`, and the live cluster has NO VWC / NO webhook-service. →
  **no injector sidecar, no certManager, no `transformations` for webhook URL/caBundle.**
  The chart stays as simple as boot-operator-remote-ddo.
- **Single upstream chart, flag-gated CRDs (shape divergence from boot).** Upstream
  publishes ONE chart `metal-maintenance-operator 0.1.0` (`oci://ghcr.io/ironcore-dev/charts`,
  alias `mmo-core`); there is NO `-crds` variant. The seed/shoot split is by
  per-component `enable` flags inside the same chart (`crd.enable`, `rbac.*`,
  `manager.enabled`, `serviceAccount.enable`, `metrics.enable`, …) — closer to metal's
  shape than boot's. Keep the pin **identical to the legacy chart's Chart.lock**
  (`mmo-core 0.1.0`, digest `sha256:c04c04d7…`) so the DDO render matches the live
  controller.
- **`manager.env` is LIST format** (`[]v1.EnvVar`, the kubebuilder-generated template),
  NOT the map form metal/boot use. The CR seedValues must supply env as a list
  (`- name: … value: …`), not a map, or the render drops/garbles env.
- **Telemetry-events Service is ON (seed-side).** Upstream default
  `telemetry.events.serviceEnabled=true` → a Service on `:9092` (BMC Redfish event
  receiver); master doesn't override; live seed has the `-telemetry-events` Service.
  Preserve it on the seed render.
- **MMO owns TWO namespaces** (legacy `managedresources/namespace.yaml`):
  `metal-maintenance-operator-system` and `metal-maintenance-sanitization`. Verify
  keepObjects on the legacy MRs and decide whether DDO re-creates them (shoot render) or
  they are left standing — the cutover must NOT cascade-delete them. (Builder gate; see §5.)
- **Cross-operator + OIDC-IAS RBAC (load-bearing, region-templated).** Beyond the
  subchart RBAC, the legacy `managedresources/rbac.yaml` carries SAP-added objects that
  MUST survive on the shoot render:
  - `metal-maintenance-token-rotate` SA (kube-system) + ClusterRole (`tokenreviews`
    create) + ClusterRoleBinding + namespaced Role (`serviceaccounts/token` create,
    resourceName `metal-maintenance-operator-controller-manager`, kube-system) + RoleBinding.
  - `metal-maintenance-operator-viewer` ClusterRole (serverwirings + consoles
    get/list/watch).
  - OIDC-IAS bindings `cc:oidc-ias-maintenance-viewer` + `cc:oidc-ias-maintenance-editor`
    to Group `CC_IAS_CONTROLPLANE_QA_DEVELOPER` (qa-de-*) / `CC_IAS_CONTROLPLANE_PROD_DEVELOPER`
    — **region-templated via `.Values.global.region`**.
  - Per-CRD-kind admin/editor/viewer helper ClusterRoles.
  The subchart's `rbac.*` toggles do NOT produce these. (See the RBAC-fidelity builder
  gate in §4a.)
- **Chart `mode` is operator-owned** — the chart MUST NOT set `.Values.mode`; DDO injects
  seed/shoot and rejects any user values containing `mode`.
- **Chart version must be clean semver** (metal lesson #1: `_sha` suffix → "improper
  constraint" → SeedRenderFailed). Use `0.1.x`.
- **Images: GHCR default in the public chart, keppel mirror override in kube-secrets**
  (metal lesson #2). Controller image default
  `ghcr.io/ironcore-dev/metal-maintenance-operator-controller-manager`; kube-secrets
  overrides repository to `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/…`.
  The **sanitizer image** is a second image (passed via `--sanitization-image` arg);
  the live per-cluster overlay pins `sanitizer:4aa31598…` (tag), which overrides the
  helm-charts values.yaml digest pin (`sanitizer@sha256:82f78c3d…`) — carry the live tag
  into the CR.
- **`charts/*.tgz` is gitignored — never commit it.** Only `Chart.lock` is committed
  (disco-ddo's missing Chart.lock is a known defect — do NOT repeat it).
- **Load-bearing identity:** `fullnameOverride: metal-maintenance-operator`; controller
  Deployment `metal-maintenance-operator-controller-manager`; SA
  `metal-maintenance-operator-controller-manager` in **kube-system**; token-requestor
  Secret `metal-maintenance-operator-remote-kubeconfig`.
- **Selector-label parity (⚠ load-bearing).** Upstream Deployment selector matchLabels =
  `{app.kubernetes.io/name: metal-maintenance-operator, control-plane: controller-manager}`.
  The DDO render MUST reproduce the live selector exactly, or the immutable-selector
  collision bites. (Verify live selector during build; SeedFirst + Recreate avoids the
  collision window, but the final selector must match any Service/NetworkPolicy the
  operand chart emits.)
- **Shared namespace** — ~9+ releases share shoot--cp--m-qa-de-200. Teardown ownership is
  by `meta.helm.sh/release-name` annotation / DDO `owned-by` label, NEVER a name prefix.
- **Cluster-authoritative image-pull verification** (metal lesson #5): `kubectl run` the
  exact controller + sanitizer refs, watch StartError/Completed vs ErrImagePull, then
  delete. Both images are already live, so low-risk, but keep the check.

## 4. Approaches considered

### 4a. The operand chart — wrapper necessary; controller rendered by the subchart

Decided in brainstorming:
- **A wrapper (new operand chart) IS necessary.** DDO renders one chart twice with
  `mode` guards and applies raw objects via SSA; the legacy `metal-maintenance-operator-remote`
  chart has no `mode` awareness and delivers shoot objects as ManagedResources — the exact
  model DDO replaces. Pointing DDO at the legacy chart is impossible (duplicate renders, MR
  wrappers); mutating the legacy chart in place would break other GRM consumers. Rejected both.
- **The controller Deployment is rendered by the upstream subchart**, NOT hand-authored.
  MMO (webhook-less) needs no init-container sidecar, no macdb volume — the subchart's
  `manager.*` values already cover args, env (list form), ports, `extraVolumes`/
  `extraVolumeMounts` (how the legacy chart wires `remote-kubeconfig`), `pod.labels`,
  `strategy`, `serviceAccountName`, `podSecurityContext`. So the operand chart carries
  **no controller template** — the mode split lives in the DDO CR's seed/shootValues.

**Resulting operand chart (thin):**
```
system/metal-maintenance-operator-remote-ddo/
  Chart.yaml            # dep: metal-maintenance-operator alias mmo-core 0.1.0 (+ owner-info if render parity needs it)
  Chart.lock            # committed; charts/*.tgz gitignored
  values.yaml           # fullnameOverride: metal-maintenance-operator; mmo-core flags all OFF by default
  templates/
    _helpers.tpl              # mode guards + chart.labels/selectorLabels/additionsAnnotations (from boot, renamed)
    remote-kubeconfig.yaml    # Secret, token-requestor (mode=seed)        [sapcc addition]
    telemetry-events-service.yaml?  # :9092 Service (mode=seed) — ONLY if subchart can't emit it; see builder gate
    networkpolicy.yaml?       # (mode=seed) — if legacy/live has one        [sapcc addition]
    oidc-ias-rbac.yaml?       # cross-operator + OIDC-IAS RBAC (mode=shoot) — if subchart can't reproduce it [sapcc addition]
```
No webhook-*, no macdb, no dns-record, no controller-manager template.

**CRDs + RBAC + controller** come from the subchart via CR seed/shootValues:
- `seedValues.mmo-core`: `manager.enabled: true`,
  `crd.enable: false`, `webhook.enable: false`, `certManager.enable: false`,
  `metrics.enable: false`, `prometheus.enable: false` (match legacy seed render).
- `shootValues.mmo-core`: `crd.enable: true`, `manager.enabled: false`,
  `serviceAccount.enable: true`, `webhook.enable: false`, `certManager.enable: false`,
  `metrics.enable: false`, `prometheus.enable: false`, **and the exact RBAC flag set
  below** (mirrors legacy `values-managed-resources.yaml`: CRDs+RBAC → shoot, controller
  → seed).

> **⚠ CR-shape correction — there is NO `rbac.enable` toggle (VERIFIED in subchart
> `0.1.0`).** Unlike boot/argora (whose subcharts use `rbac: {enable: true}`), the
> `metal-maintenance-operator` subchart's RBAC is controlled by **two** flags:
> `rbac.namespaced` (bool) and `rbac.helpers.enable` (bool). A `rbac: {enable: true}` in
> the CR would be **silently ignored**. The correct shootValues RBAC block is:
> ```yaml
> rbac:
>   namespaced: false        # → ClusterRole/ClusterRoleBinding (legacy shoot used false)
>   helpers:
>     enable: true           # → emit the per-kind admin/editor/viewer helper ClusterRoles
> ```
> **Why `helpers.enable: true` (not the subchart default `false`):** the tracked
> `values-managed-resources.yaml` says `helpers.enable: false`, but the LIVE baked
> `managedresources/rbac.yaml` (47 helper admin/editor/viewer role refs) and the 60 live
> `mr-cr-metal-maintenance-*` ManagedResources on the seed prove the shoot grant in
> production INCLUDES the helper roles — the baked artifact diverges from the tracked
> input. To preserve the live grant, the DDO shoot render must emit them →
> `helpers.enable: true`. The render-diff gate (below) is the authority; this is the
> starting hypothesis.
>
> Subchart RBAC guard facts (from `/tmp/mmo-pull/metal-maintenance-operator/templates/rbac/`):
> `manager-role`, `manager-rolebinding`, `leader-election-role{,binding}` are
> **unconditional** (always render; `manager-role`/`-rolebinding` honor `namespaced`);
> helper `*-{admin,editor,viewer}-role` are gated by `rbac.helpers.enable`; `metrics-auth-*`
> + `metrics-reader` gated by `metrics.enable AND metrics.secure`; the SA
> (`controller-manager.yaml`) by `serviceAccount.enable != false`.

> **⚠ RBAC/namespace-fidelity builder gate (P1 — settled procedure).** The subchart's
> `rbac.*: true` does NOT reproduce the legacy baked RBAC verbatim, AND the legacy
> `managedresources/rbac.yaml` carries SAP-added cross-operator + OIDC-IAS objects the
> subchart has no concept of (token-rotate SA/CR/CRB/Role/RB, viewer ClusterRole,
> `cc:oidc-ias-maintenance-{viewer,editor}` region-templated Group bindings, per-kind
> helper roles). Also the legacy `managedresources/namespace.yaml` creates two namespaces.
>
> **Required procedure:** render the DDO operand shoot render (`helm template --set
> mode=shoot`) and diff its full object inventory (kind + name + rules + subjects) against
> the legacy `managedresources/{crds-and-rbac.yaml,rbac.yaml,namespace.yaml}` set. Produce
> a shoot-side result that is functionally ≥ the legacy grant. Resolution order:
> (a) match legacy by setting the same subchart toggles the legacy chart used;
> (b) for objects the subchart CANNOT produce (the SAP cross-operator + OIDC-IAS RBAC, the
> two namespaces), carry a **mode=shoot additions template** (`oidc-ias-rbac.yaml`,
> `namespace.yaml`) in the operand chart, region-templated via `global.region` exactly as
> legacy. Any divergence from the legacy grant is documented in the chart README, never
> silent. Escalate only if the diff reveals a grant that neither a toggle nor an additions
> template can supply.

> **⚠ Telemetry-events Service builder gate (P2 — corrected by subchart inspection).**
> The subchart template `templates/extras/controller-manager-telemetry-events.yaml`
> (Service, `:9092`, name `events`, selector `app.kubernetes.io/name` +
> `control-plane=controller-manager`) renders **UNCONDITIONALLY** — it is NOT gated by
> `telemetry.events.serviceEnabled`, NOR by `manager.enabled`, NOR by `mode`
> (`serviceEnabled` is only consulted by `ingress.yaml`). Consequences for BOTH renders:
> - **Seed render:** the Service renders — correct, matches the live `-telemetry-events`
>   Service. No action needed.
> - **Shoot render:** the Service ALSO renders (even with `manager.enabled: false`,
>   `metrics.enable: false`) — WRONG; the shoot must not carry this seed-only Service. The
>   metrics Service is gated by `metrics.enable` (off → absent), but the telemetry Service
>   is not, so it leaks.
>
> **Settled remediation:** add a shoot-scoped DDO `filterKinds` transformation to drop it
> from the shoot render only (same pattern boot uses for its metrics Service):
> ```yaml
> transformations:
>   - filterKinds:
>       kinds: [Service]
>       source: upstream     # drops ONLY subchart-origin Services; spares additions-origin
> ```
> Because DDO transformations are render-global, `source: upstream` + `kinds: [Service]`
> drops the telemetry (and any other subchart) Service from BOTH renders — which is why
> any seed-side Service the operand chart needs must be an **additions-origin** template
> (stamped `origin: additions`), spared by the `source: upstream` selector. MMO's seed
> telemetry Service comes from the subchart, so if the seed must keep it, the builder
> either (a) re-emits it as an additions template and filters all upstream Services, or
> (b) scopes the filter so the seed keeps the subchart Service. Verify by rendered
> inventory: seed keeps `:9092`, shoot drops it.

### 4b. kube-secrets CR delivery

- **No new pipeline.** The CR is delivered by the already-wired `dual-deployment-operator`
  release. MMO becomes a new entry in the SAME two files the metal/boot/argora CRs use:
  - `values/helm/admin-k3s/dual-deployment-operator.yaml` →
    `dualDeploymentOperatorCRDefaults.metal-maintenance-operator-remote` (shared:
    shootNamespace kube-system, applyOrder SeedFirst, source repo/name, image repo
    overrides, seed/shootValues, args/env defaults with `${REGION}`/`${CLUSTERTYPE}`
    tokens). **ONE `transformations` entry is required** — see the telemetry-Service
    filter below (webhook-less, so NO `rewriteWebhookURL` / injector-label patch, but the
    unconditional telemetry Service still needs a shoot-side filter).
  - `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` →
    `dualDeploymentOperatorCRs.metal-maintenance-operator-remote` (per-cluster diff:
    enabled, source.version, shootAccess.server, KUBERNETES_SERVICE_HOST, global.region/
    clusterType, image tag if canaried).
- **shootNamespace:** `kube-system` (the MMO SA lives there; token-requestor Secret
  annotation targets kube-system).
- **Source of truth for the per-cluster args/env** is the existing legacy region overlay
  `values/helm/admin-k3s/qa-de-1/a-qa-de-200/metal-maintenance-operator-remote.yaml`:
  - `mmo-core.manager.args` (wholesale list): `--metrics-bind-address=:8443`,
    `--health-probe-bind-address=:8081`,
    `--sanitization-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/sanitizer:4aa31598…`,
    `--sanitization-namespace=metal-maintenance-sanitization`,
    `--report-base-url=https://metal-maintenance-operator.${CLUSTERTYPE}.${REGION}.cloud.sap`
    (live clusterType=`garden2`, region=`qa-de-1`), `--manager-namespace=metal-servers`.
  - `mmo-core.manager.env` (LIST form):
    `KUBERNETES_SERVICE_HOST=api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap`,
    `ENABLE_WEBHOOKS='false'`.
  These move into the CR seedValues/values so the DDO render reproduces them exactly;
  per-cluster overlay sets only global.region/clusterType + the apiserver host + version.

### 4c. Cutover profile (toolkit already generalized)

The generalized cutover toolkit already exists (`system/dual-deployment-operator/cutover/`,
branch `feat/ddo-cutover-toolkit`, PR #13167) with profiles for
metal/boot/argora/disco/ipam/kube-state-metrics. MMO adds ONE profile +
tests, no engine changes expected. The MMO profile fields (boot-profile schema):
- `RELEASE=metal-maintenance-operator-remote`
- `DDO_CR=metal-maintenance-operator-remote`
- `LEGACY_CHART_DIR=system/metal-maintenance-operator-remote`
- `OPERAND_CHART_DIR=system/metal-maintenance-operator-remote-ddo`
- `DEPLOY=metal-maintenance-operator-controller-manager`
- `CONTROLLER_POD_SELECTOR` = live selector (verify; `app.kubernetes.io/name=metal-maintenance-operator,control-plane=controller-manager`)
- `CRD_GROUPS` = 5 groups: `system.metal.ironcore.dev`, `baseboard.metal.ironcore.dev`,
  `vendorconsole.metal.ironcore.dev`, `maintenance.metal.ironcore.dev`,
  `readiness.metal.ironcore.dev`
- `NAMESPACE_CASCADE_GATE` — **likely `on`** (legacy owns 2 namespaces via MR); verify
  keepObjects + whether DDO owns them, then set the gate + mr-name/ns accordingly.
- `FREEZE_KINDS_*` / `FREEZE_SERVER_STATES` — assert no MMO CR
  (biossettings/bmcsettings/servermaintenances/serverwirings/…) is Terminating; MMO has a
  hardware/maintenance state machine, so freeze is non-trivial (builder refines predicate).
- `BASELINE_SNAPSHOT_KINDS_*`, `VERIFY_SAMPLE`, `OWNED_BY_LABEL=dual-deployment-operator.cc.sap/owned-by`.

## 5. The cutover shape (MMO specifics)

Same coordinated single-window cutover:
```
uninstall metal-maintenance-operator-remote  →  (merge DDO CR PR, reconcile)  →  DDO renders & applies
```
MMO specifics:
- **Namespace-cascade risk is REAL and CONFIRMED live** (unlike boot). Legacy
  `templates/managedresource.yaml` sets `keepObjects: true` ONLY for
  `kind == CustomResourceDefinition`; the two Namespace MRs get none. Verified on the seed:
  `kubectl get mr mr-n-metal-maintenance-operator-system mr-n-metal-maintenance-sanitization
  -o jsonpath '{.spec.keepObjects}'` → **both empty/false**. So a plain legacy
  `helm uninstall` WILL GRM-cascade-delete `metal-maintenance-operator-system` +
  `metal-maintenance-sanitization` **and all their contents** (sanitization jobs, etc.).
  DDO can't backstop this: it applies only AFTER the CR PR merges, which is AFTER uninstall,
  so there is an unavoidable gap if the namespaces are torn down first.
  **Settled remediation (plan a):** BEFORE the legacy uninstall, the cutover patches the two
  live Namespace MRs to `keepObjects: true`
  (`kubectl patch mr mr-n-… --type merge -p '{"spec":{"keepObjects":true}}'`) so uninstall
  leaves the namespaces standing; the DDO shoot render then re-asserts/owns them (additions
  `namespace.yaml`, `origin: additions`). The cutover profile `NAMESPACE_CASCADE_GATE` is a
  DETECTION gate (it blocks if keepObjects is not set) — the patch is the remediation, run
  explicitly as a named pre-uninstall step with who/when recorded in the runbook.
- **Freeze gate**: assert no MMO CR across the 5 groups is Terminating (BIOS/BMC
  settings, versions, servermaintenances, serverwirings, consoles). This is a real
  hardware-maintenance state machine, so freeze is more like metal than boot.
- **CRD keepObjects:** verify the legacy CRD MRs have keepObjects:true → uninstall
  preserves CRDs + CR data. (Note: the shoot also carries OLDER `*.metal.ironcore.dev`
  CRDs that belong to **metal-operator, not MMO** — MMO owns only the system/baseboard/
  vendorconsole/maintenance/readiness groups. Do NOT touch metal-operator's CRDs.)
- **Cross-operator RBAC survival:** the token-rotate role set + OIDC-IAS bindings must be
  present post-cutover (DDO-owned) — add them to `VERIFY_SAMPLE`.

## 6. Branch / PR hygiene

- ONE feature branch off `master` → ONE PR to master (fresh worktree).
- Proposed branch: `feat/metal-maintenance-operator-remote-ddo-m-qa-de-200`.
- Three deliverables across the repos:
  - helm-charts (public): operand chart `system/metal-maintenance-operator-remote-ddo`.
  - kube-secrets (internal): CR defaults block + a-qa-de-200 instance overlay.
  - cutover profile on the existing `feat/ddo-cutover-toolkit` branch (PR #13167).
- **Publish precondition** (metal lesson #7): the operand chart version must be published
  to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm` before the kube-secrets CR referencing
  it merges (else SeedRenderFailed). Verify with `helm show chart
  oci://.../metal-maintenance-operator-remote-ddo --version X`.
- Merge order: helm-charts operand PR merges + chart published → kube-secrets CR PR merges
  → live cutover.

## 7. Verification path (cluster-authoritative)

- `helm template --set mode=seed|shoot` renders clean.
- shoot render emits the 12 MMO CRDs (5 groups) + RBAC functionally ≥ legacy
  `managedresources/{crds-and-rbac.yaml,rbac.yaml}`, including the cross-operator +
  OIDC-IAS objects (region-templated) + the 2 namespaces.
- seed render emits the controller with the live selector, env in LIST form,
  the remote-kubeconfig token-requestor Secret, and the telemetry-events Service.
- Image pullability (controller + sanitizer) verified via `kubectl run` on-cluster.
- Post-cutover: DDO CR `metal-maintenance-operator-remote` Ready=True; controller
  Deployment recreated, DDO-owned (`owned-by` label), 1/1; MMO CRDs owned-by stamped, UID
  unchanged vs baseline; token-rotate RBAC + OIDC-IAS bindings present; the two namespaces
  intact; metal-operator's CRDs/data untouched.
- Dry-run of the cutover (`--operator metal-maintenance --phase uninstall --dry-run` or
  the profile equivalent) passes all read-only gates before any live step.

## 8. Left to the builder

- Exact subchart `crd`/`rbac` shoot-render fidelity vs legacy
  `managedresources/{crds-and-rbac.yaml,rbac.yaml}` (RBAC builder gate §4a); carry a
  mode=shoot additions template for the SAP cross-operator + OIDC-IAS RBAC and the two
  namespaces, region-templated, documented in the README.
- Whether the telemetry-events Service is subchart-emitted (preferred) or needs an
  additions template (§4a P2).
- Final selector/label reconciliation between subchart Deployment and any
  Service/NetworkPolicy the operand chart emits; confirm the live selector by inspection.
- The `manager.env` LIST-vs-map handling in CR seedValues (must be list form).
- `NAMESPACE_CASCADE_GATE` wiring for the cutover profile (confirm legacy MR keepObjects +
  whether DDO owns the namespaces).
- Chart version number (start 0.1.0) and keppel publish/CI mechanics.
- Whether `owner-info` dependency is needed in the operand chart (legacy chart has it;
  decide by render parity, not cargo-cult).
