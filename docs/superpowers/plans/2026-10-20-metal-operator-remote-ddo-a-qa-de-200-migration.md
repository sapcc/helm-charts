# metal-operator-remote → operator-native -ddo chart (dual-deployment-operator) — a-qa-de-200 Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Hybrid plan:** code tasks (chart reconcile, kube-secrets pipeline/values) carry helm-lint/template/diff test cycles; **operational tasks** (keppel push, seed install, live cluster verification) require the operator's live `u8s` + keppel credentials and are marked **[OPERATOR-RUN]** — the implementing agent prepares artifacts/commands and the human runs them, pasting back output as the gate evidence.

**Goal:** Migrate the `metal-operator-remote` deployment for cluster **a-qa-de-200** from the legacy pre-render-and-commit wrapper chart to the operator-native `metal-operator-remote-ddo` chart driven by the `dual-deployment-operator`, validated first on a throwaway shoot and then cut over on the real a-qa-de-200 metal control plane.

**Architecture:** `dual-deployment-operator` (already installed per-seed via `system/dual-deployment-operator` chart + `cc/kube-secrets` `dual-deployment-operator-admin-k3s` pipeline) renders the `metal-operator-remote-ddo` chart twice (mode=seed / mode=shoot) and applies each render directly via SSA — seed objects in the seed CP namespace, shoot objects in the metal shoot — replacing the Gardener ManagedResource + pre-rendered YAML model. Per-cluster config moves from the old deploy-time Helm values overlay into a `DualDeploymentOperator` CR delivered by a new `cc/kube-secrets` instance pipeline; the only runtime secret (macdb BMC credentials) stays as `vault+kvv2://` refs resolved in-cluster by the seed secrets-injector.

**Tech Stack:** Helm 3 (OCI subchart `metal-operator 0.6.2-crds` from `oci://ghcr.io/ironcore-dev/charts`), keppel OCI chart registry (`oci://keppel.eu-de-1.cloud.sap/ccloud-helm`), `dual-deployment-operator` (Go/kubebuilder, CRD `dual-deployment-operator.cc.sap/v1alpha1`), `cc/kube-secrets` Concourse `HelmChartPipeline` (Ruby ERB), `u8s` CLI for seed/cluster access, Gardener (shoots, token-requestor kubeconfigs, AdminKubeconfigRequest).

**Spec:** This plan is grounded in:
- Issue `cc/unified-kubernetes#1379` (fleet rollout; metal-operator is slice 1, a-qa-de-200 is shoot 1) and parent `#1294` (DDO proven on metal-operator in QA).
- PR `sapcc/helm-charts#12484` branch `metal-operator-remote-v2-redesign-report` — the authoritative 22-file chart + `README.md` (§2 operator contract, §4 mode-gating, §5 values-relocation) + `examples/TEST-PLAN.md` (executed end-to-end on throwaway `test-qa-de-1`, 2026-08) + `examples/dualdeploymentoperator-test-qa-de-1.yaml` (reference CR).
- Journal entries `20260803-120529-399`, `20260721-205809-452`, `20260803-101801-451`.

## Global Constraints

- **Chart `mode` is operator-owned.** The chart MUST NOT set `.Values.mode`; the operator injects `seed`/`shoot` and rejects any render whose user values contain `mode`. Source: PR `values.yaml` MODE CONTRACT header; operator `internal/source/helm.go`.
- **`charts/*.tgz` is gitignored — NEVER commit it.** Only `Chart.lock` is committed; the subchart tarball lives solely inside the published artifact. Source: PR `README.md` "Subchart vendoring model".
- **Subchart pin:** `metal-operator` `0.6.2-crds` from `oci://ghcr.io/ironcore-dev/charts`, alias `metal-operator-core`, digest `sha256:eedd0a2eb048b7c9580e3315c6fd710266da468e6cc3abd5c88400e193545beb` (Chart.lock). Do not bump without updating Chart.lock + CR + this plan.
- **Chart version and keppel publish:** The CI `helm-dep-up` Concourse job auto-publishes to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm` after merge to `master`, bumping the patch version. The CR's `spec.source.helm.version` MUST match the actually-published version (check Task 6 gate). keppel tag-protects existing versions; the CI job handles version bumping automatically.
- **Seed image egress:** the seed CP namespace has NO egress to `ghcr.io` (deny-all + label-gated allow → keppel only). ALL images in the CR (controller, probe, probe-os, operator) MUST be keppel/keppel-mirror references, never raw `ghcr.io`. Source: TEST-PLAN §3a.
- **macdb BMC credentials stay as `vault+kvv2://` refs** in the CR `macdb.macPrefixes[].defaultCredentials`; resolved in-cluster by the seed secrets-injector webhook. NEVER put real credentials in git. Source: PR README §5, TEST-PLAN §3a.
- **Seed access is always `u8s`.** Target the seed via `u8s kubectl --context <seed>` and `U8S_CONTEXT=<seed> u8s helm3 ...` (helm3 takes context via env var, not `--context`). Never raw `helm`/`kubectl` against a seed. Source: TEST-PLAN §Open-items 5.
- **No prod impact gate:** at every live step, the current `metal-operator-remote` release in the target seed CP namespace (and the real `m-qa-de-200` shoot) MUST remain the untouched legacy release until the explicit cutover task. Source: TEST-PLAN §6.
- **Decision Discipline:** any divergence from the PR README's recommended conventions (mode-gating model §4, values-relocation §5) or from the established `cc/kube-secrets` pipeline conventions must be flagged with a cited alternative before adoption.

## Review Focus

Inputs/failure modes the spec implies that no single task's happy-path test exercises — each gets a pinned check in its owning task:

- **Operator OCI cache staleness** — re-pushing the same chart version to keppel without an operator pod `rollout restart` makes the operator report `SeedRenderFailed: oci pull ... not found` on a chart that is present. Pinned in Task 6 (publish) + Task 10 (deploy) as a mandatory restart-or-bump step. Source: TEST-PLAN §6a.
- **Reconcile one-cycle lag** — prune/transform changes land on the *next* reconcile, not immediately; asserting too early reads a false failure. Pinned in Task 11 verification as a "wait ≥1 resync or annotate-to-force" instruction. Source: TEST-PLAN §6a.
- **caBundle clobber / disjoint SSA** — the operator must NOT overwrite the webhook-injector's `caBundle` on re-apply (operator owns url/labels, injector owns caBundle). This is the whole reason the migration exists; pinned as the critical end-to-end check in Task 11. Source: TEST-PLAN §5a, §6a-3.
- **applyOrder bootstrap** — the `dual-deployment-operator-shoot-access` Secret must exist (install-chart-provisioned, `shootRbac.enabled`) before the operator reads `shootAccess`, else deadlock. Pinned as a precondition check in Task 8 + Task 10. Source: TEST-PLAN §6, CR template header.
- **CRD ownership on a-qa-de-200** — the DDO CRD must be Helm-owned (pipeline `crds_include_path_regex: "NOMATCH"`), and the `controller.crd.enabled` true/false contradiction (values says `true`, pipeline comment says non-owner `false`) must be resolved against live cluster state before deploy, or a second CRD owner collides. Pinned in Task 3. Source: recon item 5.

---

## Phase 0 — Reconcile local state & establish the working branch

### Task 1: Reconcile the divergent local chart against PR #12484

**Problem:** The local working tree has an **untracked, divergent** `system/metal-operator-remote-v2/` containing only 3 stray files (`templates/metal-operator-deployment-override.yaml`, `tests/shoot_mode_override_injection.sh`, `charts/metal-operator-0.6.2-crds.tgz`) — NOT the real 22-file chart on the PR branch. The session is also on an unrelated branch `feat/cc-shoots-workerless-controlplane-zones`.

**Rename:** the chart on PR #12484 is named `metal-operator-remote-v2`. This task adopts it AND renames it to **`metal-operator-remote-ddo`** (the `-ddo` suffix signals the chart is driven by the dual-deployment-operator, which is clearer than a bare version bump). The rename touches: the chart directory, `Chart.yaml` `name:`, all internal references in README/examples/TEST-PLAN, and the published chart/release name. The PR *branch* name `metal-operator-remote-v2-redesign-report` is a fixed remote ref and is NOT renamed.

**Files:**
- Inspect/remove: `system/metal-operator-remote-v2/` (the 3 stray untracked files)
- Create (via rename): `system/metal-operator-remote-ddo/`
- Source of truth: PR branch `metal-operator-remote-v2-redesign-report` @ `c8f1bdac`

- [ ] **Step 1:** Confirm the stray files are untracked and not referenced by any committed file: `git status --short system/metal-operator-remote-v2/` and `grep -rn "metal-operator-remote-v2" --include=*.yaml --include=*.rb . | grep -v '^system/metal-operator-remote-v2/'`. Expected: all 3 files `??`; no external references. Then remove the stray dir: `rm -rf system/metal-operator-remote-v2`.
- [ ] **Step 2:** Capture whether the stray `metal-operator-deployment-override.yaml` / `shoot_mode_override_injection.sh` contain any logic NOT present in the PR chart (diff intent against PR `templates/controller-manager.yaml` + `_webhook-injector-sidecar.tpl`). Expected: they are superseded dead experiments → safe to discard. If any unique intent is found, note it for the chart author; do NOT silently drop it.
- [ ] **Step 3:** Create the feature branch off the current `master`/integration base (per pr_workflow_preference: single feature branch → PR to main; do NOT branch off the PR branch): `git fetch origin && git checkout -b feat/metal-operator-remote-ddo-a-qa-de-200 origin/master`.
- [ ] **Step 4:** Bring the real chart onto the branch under its ORIGINAL `-v2` path: `git checkout origin/metal-operator-remote-v2-redesign-report -- system/metal-operator-remote-v2/`. Verify it matches the PR: `git diff --stat origin/metal-operator-remote-v2-redesign-report -- system/metal-operator-remote-v2/` → empty, 22 files, no `charts/*.tgz` tracked.
- [ ] **Step 5: Rename `-v2` → `-ddo`.** `git mv system/metal-operator-remote-v2 system/metal-operator-remote-ddo`. Then rewrite every internal `metal-operator-remote-v2` reference to `metal-operator-remote-ddo` across the chart tree (`Chart.yaml` `name:`, `README.md`, `examples/*.md`, `examples/*.yaml` including the CR `spec.source.helm.name` and any `helm push`/`helm show` commands in TEST-PLAN.md, release names). Use: `grep -rl metal-operator-remote-v2 system/metal-operator-remote-ddo` then an in-place replace; re-grep to confirm zero `-v2` strings remain in the chart tree. Do NOT touch the string `metal-operator-remote-v2-redesign-report` if it appears in docs (it is the PR branch name) — but the chart tree should not reference it.
- [ ] **Step 6:** Sanity re-render after rename: `helm dependency build system/metal-operator-remote-ddo && helm template system/metal-operator-remote-ddo >/dev/null` (or with `--set mode=seed`). Expected: no errors, no dangling `-v2` name references.
- [ ] **Step 7:** Commit. `git add -A system/metal-operator-remote-ddo && git commit -m "feat(metal-operator-remote-ddo): adopt + rename chart from PR #12484 (-v2 → -ddo)"`

**Decision point (surface to human):** PR #12484 is open against `master`, `blocked`, and names the chart `-v2`. Confirm the intended integration path: (a) supersede #12484 with this `-ddo`-renamed branch (one combined PR to `master`), or (b) first merge #12484 as-is then rename in a follow-up. Default per pr_workflow_preference = single feature branch → PR to `master`, superseding #12484. Do not proceed to Phase 2 kube-secrets work until the human confirms.

---

## Phase 1 — Chart validation (local, no credentials)

### Task 2: Static chart validation — lint + both-mode template renders

**Files:**
- Test (new helper, repo-local, gitignored or under chart `tests/`): `system/metal-operator-remote-ddo/tests/render-modes.sh`
- Chart under test: `system/metal-operator-remote-ddo/`

**Interfaces:**
- Produces: a repeatable local render gate used by Tasks 3/5/9 and by reviewers. Renders the chart with `--set mode=seed` and `--set mode=shoot` (test-only; the operator injects mode in prod) over a representative values set derived from the test-qa-de-1 CR's `values`/`seedValues`/`shootValues`.

- [ ] **Step 1: Write the failing render test.** `render-modes.sh` must: `helm dependency build .` (pulls subchart into `charts/`), then for each mode run `helm template . --set mode=<m> -f <extracted-values>.yaml` and assert: (seed) exactly the seed object set — `Deployment/metal-operator-controller-manager` with webhook-injector initContainer, `Secret/macdb`, `Service/metal-operator-metal-registry-service` + webhook-service, `Ingress`, 6 `NetworkPolicy`, `ConfigMap/remote-kubeconfig`; NO shoot-only objects. (shoot) upstream CRDs+RBAC+VWC, webhook-injector RBAC, oidc-ias bindings, `metal-api-viewer` ClusterRole, `Namespace/metal-servers`; NO seed objects; VWC emitted with `caBundle` UNSET and the injector label absent-until-transform. Assert NO template sets `.Values.mode`.
- [ ] **Step 2: Run it to confirm the environment gap fails first** (e.g. subchart not yet vendored). Expected: FAIL until `helm dependency build` succeeds and both renders are clean.
- [ ] **Step 3:** Fix any lint/template errors surfaced (the chart is from a reviewed PR, so expect few; this task is the gate, not a rewrite). `helm lint system/metal-operator-remote-ddo` must exit 0.
- [ ] **Step 4: Run** `bash system/metal-operator-remote-ddo/tests/render-modes.sh`. Expected: PASS both modes, object-set assertions hold, `mode` never set by a template.
- [ ] **Step 5: Commit** the render test. Do NOT commit `charts/*.tgz` (verify `.gitignore` covers it; `git status` must show no tgz staged).

### Task 3: Resolve the CRD-ownership contradiction for a-qa-de-200

**Files:**
- Read: `cc/kube-secrets` `pipelines/dual-deployment-operator-admin-k3s/pipeline.rb` + `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml`
- Possibly modify: the values file comment/flag OR the pipeline comment (whichever is wrong)

- [ ] **Step 1:** State the contradiction precisely: values sets `controller.crd.enabled: true` (a-qa-de-200 owns its CRD, separate cluster from rt-qa-de-1) while the pipeline comment claims this admin-k3s release is a NON-OWNER with `crd.enabled: false`. The pipeline ALSO sets `crds_include_path_regex: "NOMATCH"` (CRD is a Helm template, Helm-owned).
- [ ] **Step 2: [OPERATOR-RUN]** Confirm live truth on a-qa-de-200: `u8s kubectl --context a-qa-de-200 get crd dualdeploymentoperators.dual-deployment-operator.cc.sap -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}{"\n"}{.metadata.annotations.meta\.helm\.sh/release-name}'`. Expected: `Helm` + `dual-deployment-operator` (CRD owned by the DDO release) → confirms values `true` is correct and the pipeline comment is stale.
- [ ] **Step 3:** Fix the stale artifact: if live state confirms `true`, correct the pipeline comment to match (admin-k3s a-qa-de-200 IS the CRD owner; `NOMATCH` is because the CRD is a Helm template, not because it's a non-owner). If live state shows otherwise, flag to the human before changing any flag.
- [ ] **Step 4: Commit** the comment/flag correction in the kube-secrets branch (see Task 7 for branch setup; if Task 7 not yet done, defer this commit to Phase 2).

---

## Phase 2 — kube-secrets instance wiring (GitOps authoring, no live apply)

### Task 7: Create the kube-secrets working branch

**Files:** repo `/Users/D065300/IdeaProjects/sapcc/kube-secrets`

- [ ] **Step 1:** `cd /Users/D065300/IdeaProjects/sapcc/kube-secrets && git fetch origin && git checkout -b feat/metal-operator-remote-ddo-a-qa-de-200 origin/master` (confirm the integration base branch name first; the repo was last on `chore-check-placement-script`).
- [ ] **Step 2: Commit** nothing yet; branch created.

### Task 4: Author the a-qa-de-200 `DualDeploymentOperator` CR values overlay

**Files:**
- Create: `values/helm/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote-ddo.yaml`
- Reference (do NOT copy blindly): PR `examples/dualdeploymentoperator-test-qa-de-1.yaml` (the CR shape) + old `values/helm/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote.yaml` (the real a-qa-de-200 per-cluster values)

**Interfaces:**
- Produces: the `dualDeploymentOperatorCR.*` values the `metal-operator-remote-ddo` chart template (`templates/dualdeploymentoperator-cr.yaml`) consumes to render the CR. The chart's CR template keys are: `dualDeploymentOperatorCR.{enabled, namespace, shootNamespace, shootAccess.{secretName,server}, source.{repo,name,version}, values, seedValues, shootValues, transformations}`.

- [ ] **Step 1:** Set the direct-install carve-out: `dualDeploymentOperatorCR.enabled: true`, `dualDeploymentOperatorCR.namespace: shoot--cp--m-qa-de-200`, `shootNamespace: kube-system` (load-bearing — unchanged from test CR), `shootAccess.secretName: dual-deployment-operator-shoot-access`, `shootAccess.server: https://api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap`.
- [ ] **Step 2:** Set `source`: `repo: oci://keppel.eu-de-1.cloud.sap/ccloud-helm`, `name: metal-operator-remote-ddo`, `version: 0.1.0` (MUST match the pushed chart — Task 6).
- [ ] **Step 3:** Port the real a-qa-de-200 per-cluster `values` from the old overlay, translated to CR values (README §5 relocation): `global.region: qa-de-1`; `global.clusterType: garden2` (from old overlay — NOT `metal`; verify against old overlay line); `global.tld`; `controllerManager.manager.env.KUBERNETES_SERVICE_HOST: api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap`; `controllerManager.manager.args` copied verbatim from old overlay (`--registry-url=https://metal-operator-remote.garden2.qa-de-1.cloud.sap`, probe images, `--manager-namespace=metal-servers`, `--enforce-*`); `dnsRecordTemplate.enabled: true`, `zone: cc.qa-de-1.cloud.sap`; `virtualGardenLBIP: 10.246.83.235`. Controller image → keppel-mirror ref (NOT ghcr).
- [ ] **Step 4:** Port `macdb.macPrefixes` with `vault+kvv2://` refs for qa-de-1 (`vault+kvv2:///secrets/qa-de-1/ironic/ipmi-user/ironic/{username,password}`). Cross-check the prefix list against the old a-qa-de-200 overlay's macdb (NOT the test CR's — the test CR used qa-de-1 generic prefixes). If the old overlay sources macdb differently (it may rely on chart defaults), reconcile and note.
- [ ] **Step 5:** Set `seedValues`/`shootValues` for `metal-operator-core` subchart flags exactly as the PR MODE CONTRACT (seed: all off; shoot: crd/rbac/webhook on, controllerManager off). Set `transformations`: `rewriteWebhookURL` (urlPrefix `https://metal-operator-remote-webhook-service:443`) + `patch` injector label `dual-deployment-operator.cc.sap/webhook-injector: metal-operator`.
- [ ] **Step 6:** Decide `applyOrder`. The chart CR template FIXES `applyOrder: SeedFirst` (template header). The test CR used `ShootFirst`. Keep the chart's SeedFirst for the GitOps path unless a reason emerges; flag the divergence from the test CR. Document in a comment.
- [ ] **Step 7: Validate** by rendering the -ddo chart with this overlay as a direct-install (mode unset, `dualDeploymentOperatorCR.enabled=true`): `helm template system/metal-operator-remote-ddo -f <this-file>` (from a helm-charts checkout) and assert a single valid `DualDeploymentOperator` CR is produced with all required fields non-empty (the template `required`s them). Expected: PASS.
- [ ] **Step 8: Commit** to the kube-secrets branch.

### Task 5: Author the a-qa-de-200 `metal-operator-remote-ddo` instance pipeline

**Files:**
- Create: `pipelines/metal-operator-remote-ddo-admin-k3s/pipeline.rb`
- Reference: `pipelines/dual-deployment-operator-admin-k3s/pipeline.rb` (CRD-template handling, NOMATCH, kubelogon) + `pipelines/metal-operator-remote-admin-k3s/pipeline.rb` (a-qa-de-200 filter/namespace/stages/pre_release)

**Interfaces:**
- Consumes: `HelmChartPipeline.new(chart:, release:, namespace:, cluster_settings:, filter:, auth:, crds_include_path_regex:, pre_release_chart_filter:)` (recon item 4 signature).

- [ ] **Step 1:** Author the pipeline: `chart: "system/metal-operator-remote-ddo"`, `release: "metal-operator-remote-ddo"`, `namespace: "shoot--cp--m-$REGION"` with `cluster_settings: { "a-qa-de-200" => ClusterSettings.new(namespace_override: "shoot--cp--m-qa-de-200") }`.
- [ ] **Step 2:** `crds_include_path_regex: "NOMATCH"` — the -ddo chart ships the CRD INSTANCE (a `DualDeploymentOperator` CR), not a CRD definition; the DDO CRD itself is owned by the controller release. NOMATCH prevents a spurious pre-Helm apply-crds task. (Mirror the DDO controller pipeline's reasoning.)
- [ ] **Step 3:** `filter: { types: "admin-k3s", clusters: "a-qa-de-200", regions: "*", triggers: "a-qa-de-200", gates: "a-qa-de-200", stages: HelmChartPipeline.default_stages(prefix: "a") }`, `auth: :kubelogon`.
- [ ] **Step 4:** `pre_release_chart_filter`: match the publish decision — if the -ddo chart is published with a release version `0.1.0` (NOT a `0.0.0-*` prerelease), set `pre_release_chart_filter: false`. If published as a prerelease devel tag, set `true` (mirror old pipeline). Flag the coupling: this MUST agree with Task 6's published tag and Task 4's `source.version`.
- [ ] **Step 5: Validate** the pipeline renders: `cd pipelines/metal-operator-remote-ddo-admin-k3s && ruby pipeline.rb > /dev/null` (or the repo's standard `rake`/render check). Expected: valid Concourse YAML, exit 0, a-qa-de-200 job present.
- [ ] **Step 6: Commit.**

---

## Phase 3 — Publish the chart (operator-run)

### Task 6: [OPERATOR-RUN] Verify chart published to keppel after PR merge

**How it works:** The kube-secrets `helm-dep-up` Concourse job — triggered automatically when the `feat/metal-operator-remote-ddo-a-qa-de-200` PR merges to `master` in `sapcc/helm-charts` — runs `helm dependency update` + patch-version bump and pushes the packaged chart to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm`. Both the kube-secrets `HelmChartPipeline` (via the `chartmuseum` Concourse resource type pointed at `keppel.eu-de-1.cloud.sap/ccloud-helm`) and the DDO operator (via the CR's `spec.source.helm.repo`) pull from this same keppel registry. **No separate manual push is needed.**

Note: the `helm-dep-up` job bumps the patch version in `Chart.yaml` automatically. After merge, the published chart version will be `0.1.1` (or whichever bump it lands on), NOT necessarily `0.1.0`. Task 4's `source.version` must match the actually-published version — update it after confirming the published version in this task's gate.

**Files:** none committed here. The version bump commit is authored by `helm-dep-up` in the CI job.

- [ ] **Step 1:** After the PR merges, watch the `helm-dep-up` Concourse job for the `metal-operator-remote-ddo` chart. Confirm it runs to green.
- [ ] **Step 2: Gate (human pastes output):** `helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-operator-remote-ddo --version <bumped-version>` → exit 0, `name: metal-operator-remote-ddo`. Note the actual published version.
- [ ] **Step 3:** Update Task 4's kube-secrets overlay `source.version` to the actually-published version if it differs from `0.1.0`. Commit the update to the kube-secrets branch before Phase 4.
- [ ] **Step 4 [OPERATOR-RUN] — OCI cache:** If the DDO operator is already running on the target seed and the chart was previously published at the same version, `rollout restart deploy/dual-deployment-operator-controller-manager` in the target namespace to clear the in-pod OCI resolution cache. **Review Focus (OCI cache):** failure to restart causes `SeedRenderFailed: oci pull ... not found` even though the chart is present.

---

## Phase 4 — Validate on a throwaway shoot (operator-run, proves chart+operator mechanics)

> Rationale (user decision): stage through a throwaway `qa-de-1` workerless shoot before touching the real a-qa-de-200 metal control plane. This validates chart renders + operator two-render + SSA + caBundle disjointness + teardown, per the already-executed TEST-PLAN, but NOT a-qa-de-200's exact seed wiring (recon item 6).

### Task 8: [OPERATOR-RUN] Stand up the throwaway shoot + install/confirm the operator

- [ ] **Step 1:** Create the throwaway workerless shoot from PR `examples/shoot-test-qa-de-1.yaml` in garden `g-qa-de-1` (project `cp`, ns `garden`). Read the assigned apiserver host once healthy (TEST-PLAN §Open-items 6).
- [ ] **Step 2:** Install/confirm the `dual-deployment-operator` on seed `rt-qa-de-1` into ns `shoot--cp--test-qa-de-1` per TEST-PLAN §2b (`ENABLE_WEBHOOKS=false`, `shootRbac.enabled=true`, keppel image). **Precondition check (Review Focus applyOrder):** confirm `dual-deployment-operator-shoot-access` Secret exists before applying any CR.
- [ ] **Step 2 Gate:** CRD present; controller Running in `shoot--cp--test-qa-de-1`, no crashloop, no DNS/egress errors; ClusterRole present.

### Task 9: [OPERATOR-RUN] Apply the test CR + verify both renders + adversarial checks

- [ ] **Step 1:** Prepare the test CR from PR `examples/dualdeploymentoperator-test-qa-de-1.yaml` with `source.version` = the pushed `0.1.0` and the throwaway shoot's apiserver host. Apply on `rt-qa-de-1` / `shoot--cp--test-qa-de-1`.
- [ ] **Step 2 Gate — seed render (TEST-PLAN §4):** exactly the seed object set; macdb refs resolved (0 `vault+kvv2` left); shoot-access token minted; 6 NetworkPolicies; NO shoot-only objects.
- [ ] **Step 3 Gate — shoot render (TEST-PLAN §5):** upstream CRDs, VWC with injector label + URL rewritten, SA in kube-system, oidc-ias bindings (4), `Namespace/metal-servers`; NO seed objects.
- [ ] **Step 4 Gate — critical e2e (TEST-PLAN §5a, Review Focus caBundle):** VWC `caBundle` becomes non-empty after the injector patches it.
- [ ] **Step 5 — adversarial (TEST-PLAN §6/§6a):** drift correction, caBundle no-clobber on operator re-apply, macdb self-heal, idempotent reconcile. **Review Focus (reconcile lag):** wait ≥1 resync or annotate-to-force before asserting prune/transform changes.
- [ ] **Step 6 — teardown (TEST-PLAN §7, order matters):** delete CR first, confirm seed+shoot objects gone, then delete the throwaway shoot. Record evidence.

---

## Phase 5 — Deploy to real a-qa-de-200 + equivalence + cutover (operator-run)

### Task 10: [OPERATOR-RUN] Deploy the -ddo instance to a-qa-de-200 via kube-secrets (alongside legacy)

**Precondition:** Phases 2–4 complete; Task 6 published; kube-secrets branch (Tasks 4/5/3) merged or applied to the a-qa-de-200 pipeline. **No prod impact gate: the legacy `metal-operator-remote` release stays untouched** — the -ddo render must land in the same seed CP namespace `shoot--cp--m-qa-de-200` WITHOUT disrupting the live release until Task 12.

- [ ] **Step 1:** Confirm DDO controller healthy on a-qa-de-200 (`shoot--cp--m-qa-de-200`), CRD Helm-owned (Task 3), `dual-deployment-operator-shoot-access` Secret present (applyOrder precondition).
- [ ] **Step 2:** Trigger the new `metal-operator-remote-ddo-admin-k3s` pipeline for a-qa-de-200 (or apply the rendered CR). **Review Focus (OCI cache):** if the chart version was re-pushed, `rollout restart` the operator first.
- [ ] **Step 3 Gate:** the `DualDeploymentOperator/metal-operator-remote-ddo` CR reaches Ready; seed render present in `shoot--cp--m-qa-de-200`; shoot render present in the real `m-qa-de-200` shoot.

### Task 11: [OPERATOR-RUN] Equivalence verification vs legacy metal-operator-remote output

- [ ] **Step 1:** Capture the legacy output: the live `metal-operator-remote` seed objects in `shoot--cp--m-qa-de-200` + shoot objects in `m-qa-de-200`.
- [ ] **Step 2:** Diff the -ddo operator-applied objects against legacy per object kind. Expected equivalence (allowing the intentional `-ddo` differences the PR README §6 documents: no ManagedResource wrapper, no `fullnameOverride` gymnastics, clean upstream RBAC kinds). Flag any UNEXPECTED divergence.
- [ ] **Step 3 Gate — critical:** VWC `caBundle` on the real `m-qa-de-200` shoot is patched by the injector and survives operator re-apply (disjoint SSA). Metal servers / BMC reconciliation behavior unchanged. Acceptance-criteria equivalence (issue #1379: ≥1 webhook-enabled shoot).

### Task 12: [OPERATOR-RUN] Cutover — retire legacy metal-operator-remote for a-qa-de-200

- [ ] **Step 1:** Once equivalence holds and bakes, remove the legacy a-qa-de-200 wiring: delete/disable the a-qa-de-200 entry from `pipelines/metal-operator-remote-admin-k3s/pipeline.rb` filter (and the old `values/.../a-qa-de-200/metal-operator-remote.yaml` once the release is gone). Uninstall the legacy `metal-operator-remote` release from `shoot--cp--m-qa-de-200`.
- [ ] **Step 2 Gate:** only the -ddo operator-managed objects remain; no orphaned ManagedResources/Secrets; `m-qa-de-200` healthy.
- [ ] **Step 3:** Update the metal-api cluster-build doc (issue #1379 ToDo) and sync with platform-delivery/foundation.
- [ ] **Step 4: Commit** the kube-secrets legacy-removal change.

---

## Phase 6 — PR & docs

### Task 13: Open PRs and update issue tracking

- [ ] **Step 1:** helm-charts: single feature branch `feat/metal-operator-remote-ddo-a-qa-de-200` → PR to `master` (pr_workflow_preference: one feature branch, one PR; reconcile with existing #12484 per Task 1 decision — either supersede or fold in, no stacked PR).
- [ ] **Step 2:** kube-secrets: feature branch → PR to its integration base.
- [ ] **Step 3:** Update issue #1379 ToDo: check off "metal-operator: author wrapper chart + CR instance; QA verify; per-shoot rollout" for a-qa-de-200; link PRs; note a-qa-de-200 is the first shoot of the metal-operator slice (remaining shoots/operators follow the same template).
- [ ] **Step 4:** Docs (@docs after verification): update chart README/examples with the a-qa-de-200 CR as a second worked example alongside test-qa-de-1.

---

## Self-Review notes

- **Spec coverage:** #1379 metal-operator ToDo (author chart ✓ Task 1-2, CR instance ✓ Task 4, QA verify ✓ Task 9/11, per-shoot rollout ✓ Task 10/12); kube-secrets pipeline wiring ✓ Task 5; equivalence ✓ Task 11; docs ✓ Task 12/13. ipam-capi kustomize egress + other 6 operators are OUT of scope (this plan is the a-qa-de-200 metal-operator slice only, per user).
- **Credentials boundary:** every live step is [OPERATOR-RUN] with a paste-back gate; the agent authors artifacts + exact commands only.
- **Open decisions surfaced, not guessed:** (1) PR #12484 integration path (Task 1); (2) CRD-ownership contradiction resolved against live state (Task 3); (3) applyOrder SeedFirst vs ShootFirst (Task 4 step 6); (4) chart version vs pre_release_chart_filter coupling (Task 5 step 4 / Task 6). Each must be confirmed before its downstream task.
- **Proportion:** plan is procedural/GitOps + live-ops, intentionally longer than a pure-code plan because the verification gates ARE the deliverable here; code-authoring tasks (4, 5) carry render/validate cycles, not full TDD, matching the Helm/Concourse domain.
