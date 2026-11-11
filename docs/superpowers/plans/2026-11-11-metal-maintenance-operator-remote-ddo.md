# metal-maintenance-operator-remote → DDO Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `metal-maintenance-operator-remote` (MMO) from Gardener-ManagedResource delivery to the DDO two-render pattern on cluster m-qa-de-200, mirroring the metal/boot/argora/disco Helm-operand migrations.

**Architecture:** A thin HELM operand chart `system/metal-maintenance-operator-remote-ddo/` depends on the upstream `metal-maintenance-operator` subchart (alias `mmo-core`, 0.1.0) with all subchart flags OFF by default. DDO renders it twice, injecting `.Values.mode` = `seed` | `shoot`: the seed render (→ a-qa-de-200) carries the controller Deployment (from the subchart via `mmo-core.manager.enabled=true`), the token-requestor Secret, and the telemetry Service; the shoot render (→ m-qa-de-200) carries the 12 CRDs, the subchart RBAC, plus SAP-added namespace + cross-operator/OIDC-IAS RBAC additions templates. Per-cluster values and the DualDeploymentOperator CR live in `cc/kube-secrets`; the cutover profile lives on the `feat/ddo-cutover-toolkit` branch. Webhook-less (matches live).

**Tech Stack:** Helm 3 (subchart dependency + OCI publish), kustomize-free, DDO CR (`source.helm`), bash CI scripts, Gardener token-requestor Secrets, keppel OCI registry.

**Spec:** `docs/superpowers/specs/2026-11-11-metal-maintenance-operator-remote-ddo-migration-design.md`

## Global Constraints

- **Chart version = clean semver `0.1.0`**, NO `_sha` suffix (a non-semver version triggers "improper constraint" → SeedRenderFailed).
- **`charts/*.tgz` gitignored; `Chart.lock` committed** (the publish workflow packages the complete artifact; the operator pulls it without dep-resolution at apply time).
- **`fullnameOverride: metal-maintenance-operator`** is load-bearing — every object name derives from it. Controller Deployment + SA = `metal-maintenance-operator-controller-manager`; token-requestor Secret = `metal-maintenance-operator-remote-kubeconfig`.
- **The chart MUST NOT set `.Values.mode`** — DDO injects it; a render whose user values contain `mode` is rejected. CI gate `no-mode-default.sh` enforces this.
- **Subchart alias is `mmo-core`**; its RBAC flags are `rbac.namespaced` (bool) + `rbac.helpers.enable` (bool) — there is **NO `rbac.enable` toggle** (a boot/argora-style `rbac: {enable: true}` is silently ignored). Controller flag is `mmo-core.manager.enabled` (NOT `controllerManager.enable`). Cert flag is `certManager.enable` (capital M).
- **`shootNamespace: kube-system`** in the CR is load-bearing (the controller SA lives there).
- **Images: GHCR default in the public chart; keppel-mirror override** (`keppel.global.cloud.sap/ccloud-ghcr-io-mirror/...`) in the kube-secrets CR values (the seed has no GHCR egress). The sanitizer is a second image passed via `--sanitization-image`.
- **No vault refs in the CR** (the admin-k3s helm-diff secrets-injector gate forbids vault refs outside a Secret kind). MMO has no macdb, so this is naturally satisfied.
- **PUBLISH-BEFORE-MERGE:** publish the operand chart to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-maintenance-operator-remote-ddo` and verify with `helm show chart` BEFORE the kube-secrets CR referencing it merges.
- **manager.env is LIST format** (`[]v1.EnvVar`) — the upstream chart uses a kubebuilder-generated template, unlike boot. A wholesale list replacement on deep-merge drops any default entry (e.g. `POD_NAMESPACE`); preserve it or use `manager.envOverrides` (map form) to add without clobbering.
- **DDO transformations are render-global** (apply to BOTH seed and shoot). `filterKinds {source: upstream}` drops subchart-origin objects from both renders; any seed object the operand must keep has to be additions-origin (`dual-deployment-operator.cc.sap/origin: additions`).
- **Integration branch is `master`** (not main). **EXPLICIT model on every subagent dispatch** (defaults are rejected by the proxy; use `anthropic/claude-sonnet-4-6`, `openai/gpt-6.1-sol`, `openai/gpt-6-astra`, or `github-copilot/gpt-6-luna`).

## Review Focus

- **Shoot RBAC under-grant** — the render-diff gate (Task 6) must confirm the DDO shoot render is functionally ≥ the LIVE shoot RBAC grant, not merely ≥ the tracked `values-managed-resources.yaml` (the tracked file sets `helpers.enable=false` but the live artifact has ~47 helper roles). An under-grant silently breaks the operator's RBAC at cutover. Covered by Task 6.
- **Telemetry Service leaking into the shoot render** — the subchart's telemetry Service renders unconditionally (no mode/flag guard), so without the `filterKinds` transformation it would wrongly appear shoot-side. Covered by Task 6 render check + Task 8 CR transformation.
- **Namespace cascade-delete at cutover** — the two Namespace MRs have `keepObjects: false` live, so a plain `helm uninstall` cascade-deletes `metal-maintenance-operator-system` + `metal-maintenance-sanitization` and their contents. The cutover profile's gate + PROTECT_MRS must cover BOTH namespaces (the gate parses only one mr+ns pair). Covered by Task 9.
- **Region-templated OIDC-IAS group binding resolving to the wrong group** — `qa-de-*` → `CC_IAS_CONTROLPLANE_QA_DEVELOPER`, else PROD; a mis-templated `contains` check silently binds QA developers to PROD groups (or vice-versa). Covered by Task 4 test.
- **`mode` unset producing a non-empty render** — if a template's mode guard is miswritten (e.g. `{{ if .Values.mode }}` instead of `{{ if eq .Values.mode "seed" }}`), an un-moded `helm template` leaks objects. Covered by Task 1 `no-mode-default.sh` + each template's explicit `eq` guard.

---

## File Structure

Operand chart `system/metal-maintenance-operator-remote-ddo/` (helm-charts, branch `feat/metal-maintenance-operator-remote-ddo-m-qa-de-200`):

- `Chart.yaml` — version `0.1.0`, single dep `metal-maintenance-operator` alias `mmo-core` @ `0.1.0` from `oci://ghcr.io/ironcore-dev/charts`. NO `owner-info` dep.
- `Chart.lock` — committed (pins the mmo-core digest).
- `.helmignore` — ignores `charts/*.tgz`.
- `values.yaml` — `fullnameOverride: metal-maintenance-operator`; `mmo-core` block all flags OFF; `global` block; MODE CONTRACT header comment.
- `templates/_helpers.tpl` — copied from boot, renamed (dual.seed/shoot, chart.*, additionsAnnotations).
- `templates/remote-kubeconfig.yaml` — `mode=seed` token-requestor Secret.
- `templates/namespace.yaml` — `mode=shoot` additions: 2 Namespaces.
- `templates/oidc-ias-rbac.yaml` — `mode=shoot` additions: token-rotate set + viewer ClusterRole + 2 OIDC-IAS bindings + bare dual-group servermaintenance-editor-role.
- `ci/no-mode-default.sh`, `ci/selector-parity.sh` — CI gates.
- `examples/rbac-parity.md` — the render-diff fidelity record.
- `README.md` — operand-chart role + scope + accepted deviations.

kube-secrets (`cc/kube-secrets`, its own branch):

- `values/helm/admin-k3s/dual-deployment-operator.yaml` — add `dualDeploymentOperatorCRDefaults.metal-maintenance-operator-remote` block.
- `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` — add the a-qa-de-200 instance (version pin + apiserver host + args).

Cutover (`feat/ddo-cutover-toolkit` branch/worktree):

- `system/dual-deployment-operator/cutover/profiles/metal-maintenance-operator-remote.env`
- `system/dual-deployment-operator/cutover/tests/mmo_profile_test.sh`

---

## Task 1: Operand chart skeleton (Chart.yaml, Chart.lock, values.yaml, _helpers.tpl, .helmignore)

**Files:**
- Create: `system/metal-maintenance-operator-remote-ddo/Chart.yaml`
- Create: `system/metal-maintenance-operator-remote-ddo/.helmignore`
- Create: `system/metal-maintenance-operator-remote-ddo/values.yaml`
- Create: `system/metal-maintenance-operator-remote-ddo/templates/_helpers.tpl`
- Create (generated): `system/metal-maintenance-operator-remote-ddo/Chart.lock`
- Test: `system/metal-maintenance-operator-remote-ddo/ci/no-mode-default.sh`

**Interfaces:**
- Produces: a helm chart that `helm dependency build` resolves and `helm template` renders empty-but-valid when `mode` is unset. `_helpers.tpl` exposes `chart.labels`, `chart.selectorLabels`, `chart.additionsAnnotations`, `dual.seed`, `dual.shoot` for Tasks 2–4.

- [ ] **Step 1: Write the failing CI gate `ci/no-mode-default.sh`** (copy boot's verbatim, adjust echo text). It greps `../values.yaml` for `^\s*mode:` and fails if present, then runs `helm template ..` and fails on error.

- [ ] **Step 2: Run it to verify it fails** — `cd system/metal-maintenance-operator-remote-ddo/ci && ./no-mode-default.sh`. Expected: FAIL (no Chart.yaml / values.yaml yet).

- [ ] **Step 3: Create `Chart.yaml`** — `apiVersion: v2`, `name: metal-maintenance-operator-remote-ddo`, `type: application`, `version: 0.1.0`, `appVersion: "0.1.0"`, a MODE-CONTRACT description comment, single dependency `{name: metal-maintenance-operator, repository: oci://ghcr.io/ironcore-dev/charts, version: 0.1.0, alias: mmo-core}`. NO owner-info dep.

- [ ] **Step 4: Create `.helmignore`** including `charts/*.tgz`.

- [ ] **Step 5: Create `values.yaml`** — MODE CONTRACT header comment (DO NOT SET mode); `fullnameOverride: metal-maintenance-operator`; `mmo-core:` block with ALL flags OFF: `crd.enable: false`, `rbac: {namespaced: false, helpers: {enable: false}}`, `serviceAccount.enable: false`, `webhook.enable: false`, `certManager.enable: false`, `metrics.enable: false`, `prometheus.enable: false` (omit `manager.enabled` — the CR drives it per mode); `global: {region: "", clusterType: "", tld: "", linkerd_enabled: false, linkerd_requested: false}`.

- [ ] **Step 6: Create `templates/_helpers.tpl`** — copy boot's verbatim; rename the header comment and the fullnameOverride default comment to MMO. Keep all define names identical (`chart.name`, `chart.fullname`, `chart.chart`, `chart.labels`, `chart.selectorLabels`, `chart.additionsAnnotations`, `dual.seed`, `dual.shoot`).

- [ ] **Step 7: Run `helm dependency build`** in the chart dir to fetch `mmo-core` 0.1.0 and generate `Chart.lock`. Expected: `charts/metal-maintenance-operator-0.1.0.tgz` present (gitignored), `Chart.lock` written with digest `sha256:…`.

- [ ] **Step 8: Run the CI gate to verify it passes** — `./ci/no-mode-default.sh`. Expected: PASS (no `mode:` in values.yaml; `helm template` renders without error — empty because all mode-guarded templates are inert when mode is unset).

- [ ] **Step 9: Commit** — `git add -f` the chart files + `Chart.lock` (force due to the `docs/superpowers/` exclude does not apply here, but `charts/*.tgz` must stay ignored; verify `git status` shows no `.tgz`). Commit: `feat(mmo-ddo): operand chart skeleton + mode-contract CI gate`.

---

## Task 2: Seed token-requestor Secret template (remote-kubeconfig.yaml)

**Files:**
- Create: `system/metal-maintenance-operator-remote-ddo/templates/remote-kubeconfig.yaml`
- Test: render assertion (inline, via `helm template --set mode=seed`)

**Interfaces:**
- Consumes: `chart.labels`, `chart.additionsAnnotations` from Task 1.
- Produces: a `Secret/metal-maintenance-operator-remote-kubeconfig` in the release namespace, present ONLY in the seed render.

- [ ] **Step 1: Write the failing render test** — a short bash check: `helm template mmo . --set mode=seed | yq 'select(.kind=="Secret" and .metadata.name=="metal-maintenance-operator-remote-kubeconfig")'` must be non-empty AND the same with `--set mode=shoot` must be empty. Save as a scratch assertion (not committed) or add to `ci/` if a render-matrix gate is desired.

- [ ] **Step 2: Run it to verify it fails** — template renders nothing (no template yet). Expected: FAIL (seed render empty).

- [ ] **Step 3: Create `remote-kubeconfig.yaml`** — mirror boot's exactly, substituting names: `{{- if eq .Values.mode "seed" }}` guard; `Secret` name `metal-maintenance-operator-remote-kubeconfig`, namespace `{{ .Release.Namespace }}`; labels = `include "chart.labels"` + `resources.gardener.cloud/purpose: token-requestor` + `resources.gardener.cloud/class: shoot`; annotations = `include "chart.additionsAnnotations"` + `serviceaccount.resources.gardener.cloud/name: metal-maintenance-operator-controller-manager` + `.../namespace: kube-system` + `.../inject-ca-bundle: "true"`; `type: Opaque`; `stringData: {token: "", bundle.crt: ""}`.

- [ ] **Step 4: Run the render test to verify it passes** — seed render contains the Secret; shoot render does not. Expected: PASS.

- [ ] **Step 5: Commit** — `feat(mmo-ddo): seed token-requestor Secret template`.

---

## Task 3: Shoot namespace additions template (namespace.yaml)

**Files:**
- Create: `system/metal-maintenance-operator-remote-ddo/templates/namespace.yaml`
- Test: render assertion (inline)

**Interfaces:**
- Consumes: `chart.labels`, `chart.additionsAnnotations` from Task 1.
- Produces: `Namespace/metal-maintenance-operator-system` and `Namespace/metal-maintenance-sanitization`, present ONLY in the shoot render, both stamped `origin: additions`.

- [ ] **Step 1: Write the failing render test** — `helm template mmo . --set mode=shoot` must contain exactly those two Namespace objects, each carrying annotation `dual-deployment-operator.cc.sap/origin: additions`; `--set mode=seed` must contain neither.

- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL (no template yet).

- [ ] **Step 3: Create `namespace.yaml`** — `{{- if eq .Values.mode "shoot" }}` guard wrapping two `---`-separated `Namespace` objects (`metal-maintenance-operator-system`, `metal-maintenance-sanitization`), each with `labels: {{ include "chart.labels" }}` and `annotations: {{ include "chart.additionsAnnotations" }}`.

- [ ] **Step 4: Run the render test to verify it passes.** Expected: PASS.

- [ ] **Step 5: Commit** — `feat(mmo-ddo): shoot namespace additions template`.

---

## Task 4: Shoot cross-operator + OIDC-IAS RBAC additions template (oidc-ias-rbac.yaml)

**Files:**
- Create: `system/metal-maintenance-operator-remote-ddo/templates/oidc-ias-rbac.yaml`
- Test: render assertion (inline)

**Interfaces:**
- Consumes: `chart.labels`, `chart.additionsAnnotations` from Task 1; `.Values.global.region` for OIDC group selection.
- Produces (shoot render only, all stamped `origin: additions`): `ServiceAccount/metal-maintenance-token-rotate` (kube-system) + its `ClusterRole` + `ClusterRoleBinding` + `Role` + `RoleBinding`; `ClusterRole/metal-maintenance-operator-viewer`; `ClusterRoleBinding/cc:oidc-ias-maintenance-viewer`; `ClusterRoleBinding/cc:oidc-ias-maintenance-editor`; `ClusterRole/servermaintenance-editor-role` (bare, dual-group).

- [ ] **Step 1: Write the failing render test** covering (a) all 9 objects present in the shoot render, none in the seed render; (b) region gating: with `--set global.region=qa-de-1` both OIDC CRBs' subject `Group` = `CC_IAS_CONTROLPLANE_QA_DEVELOPER`; with `--set global.region=eu-de-1` both = `CC_IAS_CONTROLPLANE_PROD_DEVELOPER`; (c) the bare `servermaintenance-editor-role` has `apiGroups: [maintenance.metal.ironcore.dev, metal.ironcore.dev]`.

- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL (no template yet).

- [ ] **Step 3: Create `oidc-ias-rbac.yaml`** — mirror metal's `oidc-ias-rbac.yaml` structure: single `{{- if eq .Values.mode "shoot" }}` wrapper, `---`-separated objects, each with `chart.labels` + `chart.additionsAnnotations`. Region-gated Group via `{{ if contains "qa-de-" .Values.global.region -}}CC_IAS_CONTROLPLANE_QA_DEVELOPER{{- else -}}CC_IAS_CONTROLPLANE_PROD_DEVELOPER{{- end }}`. Content exactly as the legacy `managedresources/rbac.yaml` SAP hand-adds:
  - `metal-maintenance-token-rotate`: SA (kube-system); ClusterRole (`authentication.k8s.io`/`tokenreviews`: `create`); ClusterRoleBinding → that SA; Role (kube-system, `""`/`serviceaccounts/token`: `create`, `resourceNames: [metal-maintenance-operator-controller-manager]`); RoleBinding → that SA.
  - `metal-maintenance-operator-viewer` ClusterRole: `readiness.metal.ironcore.dev`/`serverwirings` + `vendorconsole.metal.ironcore.dev`/`consoles`, verbs `get,list,watch`.
  - `cc:oidc-ias-maintenance-viewer` CRB → ClusterRole `metal-maintenance-operator-viewer`, subject region-gated Group.
  - `cc:oidc-ias-maintenance-editor` CRB → ClusterRole `metal-maintenance-operator-servermaintenance-editor-role` (the subchart-produced single-group one), subject region-gated Group.
  - `servermaintenance-editor-role` ClusterRole (bare): dual `apiGroups: [maintenance.metal.ironcore.dev, metal.ironcore.dev]` on `servermaintenances` + `servermaintenances/status`.

- [ ] **Step 4: Run the render test to verify it passes** (all three sub-assertions). Expected: PASS.

- [ ] **Step 5: Commit** — `feat(mmo-ddo): shoot cross-operator + OIDC-IAS RBAC additions`.

---

## Task 5: CI scripts, README, rbac-parity record scaffold

**Files:**
- Create: `system/metal-maintenance-operator-remote-ddo/ci/selector-parity.sh`
- Create: `system/metal-maintenance-operator-remote-ddo/README.md`
- Create: `system/metal-maintenance-operator-remote-ddo/examples/rbac-parity.md` (scaffold; filled by Task 6)

**Interfaces:**
- Consumes: the rendered chart from Tasks 1–4.
- Produces: a `selector-parity.sh` gate (or a documented decision to omit it) + README + an empty rbac-parity record for Task 6 to populate.

- [ ] **Step 1: Decide selector-parity applicability.** MMO has no boot-service analog; the comparable seed Service is the subchart telemetry Service (`metal-maintenance-operator-controller-manager-telemetry-events`, selector `app.kubernetes.io/name` + `control-plane=controller-manager`). Since that Service is subchart-produced (not an additions template this chart owns), write `selector-parity.sh` to compare the seed Deployment `metal-maintenance-operator-controller-manager` matchLabels against the telemetry Service selector, OR document in the README why selector-parity is N/A for MMO and omit the script. Record the choice in the README.

- [ ] **Step 2 (if keeping the script): Write `selector-parity.sh`** — adapt boot's: `helm template metal-maintenance-operator-remote . --set mode=seed --set mmo-core.manager.enabled=true` into a tmpfile; extract the Deployment matchLabels + telemetry Service selector (yq → jq -S); diff; FAIL on mismatch or empty.

- [ ] **Step 3: Run the chosen gate** (or skip with a README note). Expected: PASS or documented N/A.

- [ ] **Step 4: Write `README.md`** — mirror boot's: `> Role: OPERAND chart` callout; Subchart vendoring model (Chart.lock committed, charts/*.tgz gitignored, publish packages complete artifact); MMO-specific scope (webhook-less; owns 2 namespaces; telemetry Service seed-side; cross-operator + OIDC-IAS RBAC additions); Shoot RBAC parity pointer to `examples/rbac-parity.md`; `shootNamespace` must be kube-system; seed additions select upstream Deployment labels directly.

- [ ] **Step 5: Scaffold `examples/rbac-parity.md`** — mirror boot's structure (render command, Inventory-diff table headers, Accepted-deviation + Carried-additions sections) with placeholders Task 6 fills.

- [ ] **Step 6: Commit** — `feat(mmo-ddo): CI gates, README, rbac-parity scaffold`.

---

## Task 6: Dependency build + render-diff fidelity gate (P1 RBAC + P2 telemetry)

**Files:**
- Modify: `system/metal-maintenance-operator-remote-ddo/examples/rbac-parity.md` (fill it in)
- Modify: `system/metal-maintenance-operator-remote-ddo/values.yaml` only if the gate changes a default
- Test: render-diff commands (documented in rbac-parity.md)

**Interfaces:**
- Consumes: the full chart (Tasks 1–5) + the LIVE shoot RBAC (captured from m-qa-de-200) + the legacy `managedresources/rbac.yaml`.
- Produces: a signed-off fidelity record proving the DDO shoot render is functionally ≥ the LIVE grant, with the final resolved `rbac.helpers.enable` value and all accepted deviations documented.

- [ ] **Step 1: Capture the LIVE shoot RBAC baseline** — `u8s kubectl --context m-qa-de-200 get clusterrole,clusterrolebinding,role,rolebinding,serviceaccount -A -l <mmo selector or by name prefix> -o yaml` (and/or derive from the live `mr-*` MRs on the seed). Save as the comparison baseline. Use generous timeouts; fail closed.

- [ ] **Step 2: Render the DDO shoot bundle** — `helm template metal-maintenance-operator-remote . --namespace kube-system --set mode=shoot --set mmo-core.crd.enable=true --set mmo-core.manager.enabled=false --set mmo-core.serviceAccount.enable=true --set mmo-core.rbac.namespaced=false --set mmo-core.rbac.helpers.enable=true`.

- [ ] **Step 3: Diff render vs live** — build the Inventory-diff table (ServiceAccount / ClusterRole / ClusterRoleBinding / Role / RoleBinding / CRD names, render-vs-live). **Resolve the `helpers.enable` discrepancy**: the tracked `values-managed-resources.yaml` says `false` but the live artifact has ~47 helper roles — decide the final value by whether the LIVE grant includes them (starting hypothesis: `true`). If `true` is required, confirm the operand default + the CR shootValues both set `helpers.enable: true`.

- [ ] **Step 4: Classify every diff** — each render-only or live-only object is either (a) an accepted deviation (document the rationale, e.g. leader-election Role-vs-ClusterRole namespacing), or (b) a genuine gap that must be fixed (add to an additions template or flip a flag). The render MUST be functionally ≥ the live grant. Record carried additions (token-rotate set, viewer CR, 2 OIDC bindings, bare servermaintenance-editor-role from Task 4) as expected.

- [ ] **Step 5: Verify the telemetry Service split (P2)** — confirm the seed render (`--set mode=seed --set mmo-core.manager.enabled=true`) contains the telemetry Service on `:9092`, and that the shoot render still emits it (proving the `filterKinds` transformation in the CR, Task 8, is genuinely required to drop it shoot-side). Document this as the reason the CR carries one transformation despite being webhook-less.

- [ ] **Step 6: Write the findings into `examples/rbac-parity.md`** — the filled inventory table, the resolved `helpers.enable`, accepted deviations, carried additions, and the telemetry-Service note.

- [ ] **Step 7: Commit** — `docs(mmo-ddo): RBAC + telemetry render-diff fidelity record`.

---

## Task 7: Publish the operand chart to keppel OCI (publish-before-merge)

**Files:**
- No new repo files (publish is an out-of-band registry push); record the published version + digest in the PR description / rbac-parity.md.

**Interfaces:**
- Consumes: the complete chart (Tasks 1–6).
- Produces: `oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-maintenance-operator-remote-ddo:0.1.0` pullable, so the kube-secrets CR (Task 8) can reference it.

- [ ] **Step 1: `helm dependency update`** to ensure `charts/metal-maintenance-operator-0.1.0.tgz` + `Chart.lock` are current.

- [ ] **Step 2: `helm package`** the chart → `metal-maintenance-operator-remote-ddo-0.1.0.tgz` (complete artifact including the vendored subchart).

- [ ] **Step 3: `helm push`** the packaged tgz to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm`.

- [ ] **Step 4: Verify** — `helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-maintenance-operator-remote-ddo --version 0.1.0` returns the chart metadata. Expected: PASS (version 0.1.0, dep mmo-core 0.1.0).

- [ ] **Step 5: Record** the published version + digest in the operand PR description (no commit needed unless a publish manifest is tracked).

---

## Task 8: kube-secrets DualDeploymentOperator CR (defaults block + a-qa-de-200 instance)

**Files:** (repo `cc/kube-secrets`, its own branch — e.g. `feat/metal-maintenance-operator-remote-ddo-cr`)
- Modify: `values/helm/admin-k3s/dual-deployment-operator.yaml` (add the defaults block)
- Modify: `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` (add the instance)

**Interfaces:**
- Consumes: the published operand chart (Task 7) via `source.helm.name` + per-cluster `version`.
- Produces: a DDO CR that renders seed + shoot correctly on a-qa-de-200.

- [ ] **Step 1: Write a failing render/validation check** — e.g. `helm template` of the DDO chart with the merged base+instance values, OR a schema/lint check, asserting the `metal-maintenance-operator-remote` CR block exists with `shootNamespace: kube-system`, `applyOrder: SeedFirst`, `source.name: metal-maintenance-operator-remote-ddo`, and the `filterKinds` transformation. Expected: FAIL (block absent).

- [ ] **Step 2: Add the `dualDeploymentOperatorCRDefaults.metal-maintenance-operator-remote` block** — mirror `metal-operator-remote`'s shape (2-space op key, 4-space fields):
  - `shootNamespace: kube-system`; `applyOrder: SeedFirst`; `shootAccess.secretName: dual-deployment-operator-shoot-access`.
  - `source: {repo: oci://keppel.eu-de-1.cloud.sap/ccloud-helm, name: metal-maintenance-operator-remote-ddo}` (version per-cluster).
  - `values.global: {tld: cloud.sap, linkerd_enabled: false, linkerd_requested: false}`; keppel image mirror override for `mmo-core.manager.image.repository`; the `mmo-core.manager.args` wholesale list with `--report-base-url=https://metal-maintenance-operator.${CLUSTERTYPE}.${REGION}.cloud.sap`, `--sanitization-image=keppel…sanitizer:<live-tag>`, `--sanitization-namespace=metal-maintenance-sanitization`, `--metrics-bind-address=:8443`, `--health-probe-bind-address=:8081`, `--manager-namespace=metal-servers`.
  - `seedValues.mmo-core`: `manager.enabled: true`, `crd.enable: false`, `webhook.enable: false`, `certManager.enable: false`, `metrics.enable: false`, `prometheus.enable: false`.
  - `shootValues.mmo-core`: `crd.enable: true`, `manager.enabled: false`, `serviceAccount.enable: true`, `rbac: {namespaced: false, helpers: {enable: <resolved in Task 6>}}`, `webhook.enable: false`, `certManager.enable: false`, `metrics.enable: false`, `prometheus.enable: false`.
  - `transformations: [{filterKinds: {kinds: [Service], source: upstream}}]` (drops the telemetry Service from the shoot render; render-global so the seed telemetry Service must be subchart-origin on the seed — verified in Task 6).

- [ ] **Step 3: Add the a-qa-de-200 instance** in `qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` — `enabled`, `source.version: 0.1.0`, `shootAccess.server`, and `mmo-core.manager.env` (LIST form) with `KUBERNETES_SERVICE_HOST: api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap`, `KUBERNETES_CLUSTER_DOMAIN: cluster.local`, `ENABLE_WEBHOOKS: 'false'`, and `POD_NAMESPACE` preserved (or use `manager.envOverrides` map to avoid clobbering the subchart default). Set `global.region: qa-de-1`, `global.clusterType: garden2`.

- [ ] **Step 4: Run the validation check to verify it passes** — merged values render the CR with the right identity, transformation, and env. Expected: PASS.

- [ ] **Step 5: Commit** (on the kube-secrets branch) — `feat(ddo): metal-maintenance-operator-remote CR for a-qa-de-200`.

---

## Task 9: Cutover profile + test (on feat/ddo-cutover-toolkit)

**Files:** (branch `feat/ddo-cutover-toolkit`, worktree `/Users/D065300/.local/share/opencode/worktree/d812df/ddo-cutover-toolkit` — Read tool DENIED there, use shell cat)
- Create: `system/dual-deployment-operator/cutover/profiles/metal-maintenance-operator-remote.env`
- Create: `system/dual-deployment-operator/cutover/tests/mmo_profile_test.sh`

**Interfaces:**
- Consumes: the cutover engine (`cutover-ddo.sh`, `lib/cutover-safety.sh`).
- Produces: a profile whose `profile_contract` the engine accepts, with BOTH owned namespaces protected.

- [ ] **Step 1: Write the failing test `tests/mmo_profile_test.sh`** — mirror `ksm_profile_test.sh`: source the profile, assert each field's exact value, assert the file exists. Include assertions that BOTH `metal-maintenance-operator-system` and `metal-maintenance-sanitization` are protected (one via `NAMESPACE_CASCADE_GATE`, the other via `PROTECT_MRS`).

- [ ] **Step 2: Run it to verify it fails** — `bash tests/mmo_profile_test.sh`. Expected: FAIL (profile absent).

- [ ] **Step 3: Create `profiles/metal-maintenance-operator-remote.env`** — mirror `metal-operator-remote.env` (closest template — cluster-scoped CRs + namespace-owning):
  - `RELEASE=metal-maintenance-operator-remote`; `DDO_CR=metal-maintenance-operator-remote`; `LEGACY_CHART_DIR=system/metal-maintenance-operator-remote`; `OPERAND_CHART_DIR=system/metal-maintenance-operator-remote-ddo`.
  - `ROLLOUT_ORDER=` (pick an unused order relative to metal=10/boot=20; choose and document).
  - `DEPLOY=metal-maintenance-operator-controller-manager`; `CONTROLLER_POD_SELECTOR=app.kubernetes.io/name=mmo-core` (verify the live pod label; mmo-core is the subchart alias — confirm against the live Deployment labels).
  - `CRD_GROUPS=system.metal.ironcore.dev baseboard.metal.ironcore.dev vendorconsole.metal.ironcore.dev maintenance.metal.ironcore.dev readiness.metal.ironcore.dev` (verify exact separator/format against an existing multi-group profile).
  - `NAMESPACE_CASCADE_GATE='on mr-n-metal-maintenance-operator-system metal-maintenance-operator-system'` (primary) + `PROTECT_MRS='mr-n-metal-maintenance-sanitization'` (second owned namespace MR) — because the gate parses only one mr+ns pair.
  - `FREEZE_KINDS_CLUSTER` / `FREEZE_KINDS_NS` — decide which MMO CRD kinds to freeze (bios/bmc settings are the mutable ones); `FREEZE_SERVER_STATES=0` (MMO doesn't own the Server lifecycle — metal-operator does); document.
  - `BASELINE_SNAPSHOT_KINDS_CLUSTER` / `BASELINE_SNAPSHOT_KINDS_NS`; `VERIFY_SAMPLE=''` (optional); `OWNED_BY_LABEL=dual-deployment-operator.cc.sap/owned-by`.

- [ ] **Step 4: Run the test to verify it passes** — `bash tests/mmo_profile_test.sh`. Expected: PASS (all fields match; both namespaces protected).

- [ ] **Step 5: Run the shared profile-contract test** — `bash tests/cutover_profile_test.sh` (or the engine's profile loader) to confirm the `profile_contract` string parses. Expected: PASS.

- [ ] **Step 6: Commit** (on feat/ddo-cutover-toolkit) — `feat(cutover): metal-maintenance-operator-remote profile + test`.

---

## Execution notes

- **Branch/PR hygiene:** ONE operand branch `feat/metal-maintenance-operator-remote-ddo-m-qa-de-200` → ONE helm-charts PR (Tasks 1–7). The kube-secrets CR (Task 8) is its own branch/PR. The cutover profile (Task 9) lands on `feat/ddo-cutover-toolkit`. No stacked PRs.
- **Merge order:** operand PR merges + chart published (Task 7) → kube-secrets CR PR merges (Task 8) → live cutover using the profile (Task 9, independent branch).
- **Worktrees:** the operand worktree already exists at `/Users/D065300/.local/share/opencode/worktree/d812df/feat/metal-maintenance-operator-remote-ddo-m-qa-de-200`; the cutover worktree at `/Users/D065300/.local/share/opencode/worktree/d812df/ddo-cutover-toolkit`. kube-secrets at `/Users/D065300/IdeaProjects/sapcc/kube-secrets` (internal host).
- **docs/superpowers/ exclude:** files under `docs/superpowers/` need `git add -f` in the helm-charts worktree (local `.git/info/exclude` rule).
