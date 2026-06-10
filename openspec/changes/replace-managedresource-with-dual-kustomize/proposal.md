## Why

The current `metal-operator-remote` deployment uses Gardener's `ManagedResource` pattern with Makefile-driven pre-rendering: helm/kustomize produces YAML containing `ManagedResource` + `Secret` pairs that GRM on the seed unwraps and applies to the workerless cluster. This pipeline is hard to debug (state hides inside base64-encoded Secrets), tied to Gardener (no portability), requires committing pre-rendered `managedresources.yaml` files on every upstream version bump, and forces a `regen + commit` cycle through `system/Makefile` targets and `wrap-managedresources.sh`. Implementing the parent epic [`cc/unified-kubernetes#831`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/831) requires replacing this pipeline with a native dual-kustomize approach that supports `kubectl diff`-based debugging, eliminates Secret-wrapping bulk, and prepares the deployment for mid-term Flux migration.

## What Changes

**Resource delivery to workerless cluster**
- From: Helm/kustomize produces `ManagedResource` + `Secret` pairs on host; GRM unwraps them onto the workerless API server
- To: A separate kustomize root (`remote/`) applied directly to the workerless cluster via `kubectl apply -k` using the workerless kubeconfig
- Reason: Eliminates Secret-wrapping bulk, GRM dependency, and base64-blob-in-Secret debugging friction
- Impact: Breaking deployment-workflow change — pipeline now does two `kubectl apply -k` calls (remote then host) instead of one helm install/upgrade against host

**Apply ordering**
- From: Single deploy step (helm install/upgrade against host)
- To: Step 1 = `kubectl apply -k remote/` (workerless kubeconfig); Step 2 = `kubectl apply -k host/` (host kubeconfig)
- Reason: Workerless cluster must have CRDs + RBAC + WebhookConfig present before the controller pod starts on the host
- Impact: Pipeline (Concourse short-term, Flux mid-term) must perform two sequential applies; bootstrap window between steps is operationally benign (only writer is the not-yet-running controller)

**Pre-rendering and Makefile targets**
- From: `system/Makefile` targets `regen-metal-operator-remote-{crds,webhooks}`, `scripts/wrap-managedresources.sh`, and committed `managedresources.yaml` + `manifests-url-based.yaml` files
- To: All deleted; kustomize Git URL refs (`resources: https://github.com/ironcore-dev/metal-operator//config/{manager,crd,rbac,webhook}?ref=v0.4.0`) consume upstream content live at build time
- Reason: Native pipeline goal; eliminates the regen + commit cycle; upstream version bumps propagate via `?ref=` change only
- Impact: No more pre-rendered files in the repo; engineers bumping upstream metal-operator versions only update the `?ref=` field

**Webhook routing**
- From: Pre-rendered URL-based webhook config (`clientConfig.url: https://metal-operator-webhook-service:443/...`); webhook-injector sidecar reads a local `webhook-config` ConfigMap on host and pushes the full `ValidatingWebhookConfiguration` to workerless via remote-kubeconfig
- To: Upstream's service-based webhook config (`clientConfig.service: webhook-service/system`) is applied directly to workerless via the `remote/` kustomize tree (single `kustomization.yaml` pulling upstream's `manifests.yaml` via raw GitHub URL + a label patch). The webhook-injector sidecar runs in patch mode with admission-webhook bootstrap (per [SAP-cloud-infrastructure/webhook-injector#10](https://github.com/SAP-cloud-infrastructure/webhook-injector/pull/10) v2): it bootstraps `metal-operator-webhook-injector-mutator` MWC on the workerless cluster, which rewrites `clientConfig.Service` → `clientConfig.URL = https://metal-operator-webhook-service:443/<path>` synchronously at admission time. Re-applies are idempotent (admission rewrites before validation, so the K8s 3-way merge re-introduction of the Service field is sanitized in-flight). The host-side `metal-operator-webhook-service` Service grows a second port (`admission: 9444→9444`) to expose the sidecar's in-pod admission server to the workerless API server.
- Reason: Avoids the build-time URL rewrite step; admission-bootstrap pattern is GitOps-safe (idempotent re-applies); no ExternalName Service is used (Gardener's default `--enable-aggregator-routing=true` rejects ExternalName for webhook clientConfig per [k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659)).
- Impact: The local `webhook-config` ConfigMap on host is deleted. **Webhook-injector binary needs PR #10 v2 patch mode + admission-webhook bootstrap** (out-of-repo dependency). **`cc/kube-secrets` needs a coordinated change**: widen remote-kubeconfig RBAC to include `mutatingwebhookconfigurations` `create,get,list,watch,update,patch` (recommended via consumption of upstream `webhook-injector//config/rbac.yaml`); add Concourse pipeline gate task between `host/` and `remote/` apply jobs polling for the bootstrapped MWC.

**Role → ClusterRole conversion**
- From: `remote/upstream/metal-operator-crds-and-rbac/kustomization.yaml` patches upstream's `kind: Role` and `kind: RoleBinding` to `kind: ClusterRole` and `kind: ClusterRoleBinding` (introduced during the kustomize POC as a defensive measure)
- To: Upstream RBAC applied verbatim — Roles stay Roles, RoleBindings stay RoleBindings
- Reason: This was a `ManagedResource`-era workaround for GRM's namespace handling; the helm chart's bundled `managedresources/crds-and-rbac.yaml` proves un-converted Roles work in production
- Impact: Workerless cluster's RBAC layout changes shape (some leader-election roles return to namespace scope) but functional behavior matches the helm-deployed clusters

**Manager Deployment patches**
- From: Two patch files (`manager-remote-patch.yaml`, `manager-webhook-patch.yaml`); SAP-specific manager `args` (6 flags including `--mac-prefixes-file`, `--probe-image`, `--registry-url`, `--manager-namespace`) missing from the kustomize tree (only `--leader-elect` from upstream)
- To: Single consolidated `host/base/manager-patch.yaml` containing all manager Deployment customizations including the 6 restored args
- Reason: Closes a deploy-readiness gap from the kustomize POC where the args were only in helm's `values-overrides.yaml`; consolidates patch surface for review clarity
- Impact: Kustomize tree is end-to-end deploy-ready; `manager-webhook-patch.yaml`'s historical mixing of webhook concerns and macdb is resolved

**NetworkPolicies and pod-selector labels (post-PR-review equivalence closure)**
- From: Kustomize host base renders 1 NetworkPolicy (lacking `policyTypes`); helm chart renders 5 NetworkPolicies (with explicit `policyTypes`). Kustomize uses upstream's bare `app.kubernetes.io/name: metal-operator` label; helm uses chart-fullname-prefixed `metal-operator-remote`.
- To: Kustomize host base renders all 5 NetworkPolicies (matching helm's set: `metalapi-ingress-to-metal-operator-metal-registry-service-tcp-10000`, `metalapi-egress-to-ingress-nginx-controller-tcp-443`, `metalapi-ingress-from-kube-apiserver-9443`, `kube-apiserver-egress-to-metalapi`, `metalapi-ingress-from-kube-monitoring`), each with explicit `spec.policyTypes`. Pod-selector labels are aligned per the cutover decision recorded in `design.md` "Helm-vs-kustomize equivalence gap analysis": **option (a) — match the helm chart-fullname-prefixed labels** (`app.kubernetes.io/name: metal-operator-remote`). Implementation is explicit per file (NetworkPolicies, Services, and a `manager-patch.yaml` strategic-merge patch on upstream's Deployment selector + podLabels) rather than via a kustomize `labels: includeSelectors: true` directive (that approach over-injected into the apiserver NP's outer podSelector and was discarded).
- Reason: Closes the equivalence gap surfaced by helm-vs-kustomize diffing for `a-qa-de-200`/k3s-admin values. NetworkPolicies are fleet-uniform — same 4 policies render across every SAP-CC cluster — so they belong with the chart, not duplicated per-cluster overlay (consistent with the OQ10 transitivity argument that absorbed the webhook-injector RBAC into this repo). Pod-selector / Deployment-name alignment is necessary for cutover compatibility (without it, the kustomize Service finds zero endpoints during transition while helm-deployed Pods still carry the helm-naming).
- Impact: Brings kustomize-rendered output to fleet-equivalence with the helm chart's host-side resources. The cutover decision (a/b/c) is captured in `design.md` and the chosen option's mechanical consequence (e.g., `commonLabels:` block in `host/base/kustomization.yaml`) is encoded in the kustomize tree. Manager image SHA divergence (helm pin vs cc/kube-secrets per-cluster pin) is explicitly out of scope — it's an operator-time decision, not a code gap.

**Upstream metal-operator RBAC subject rebinding (post-deploy correctness fix)**
- From: `remote/upstream/metal-operator-crds-and-rbac/` consumes upstream `config/rbac/` verbatim. Three bindings (`manager-rolebinding`, `metrics-auth-rolebinding` ClusterRoleBindings; `leader-election-rolebinding` RoleBinding) reference upstream's bare `controller-manager` SA. Live deploy on `a-qa-de-200` showed the controller-manager Pod logging a forever-loop of `forbidden` on every list/watch — the remote-kubeconfig token authenticates as the Gardener-prefixed `metal-operator-controller-manager` SA (created by the token-injector in response to the host-side Secret annotation), but no upstream binding references that identity.
- To: Three JSON Patch `op: replace` patches in `remote/upstream/metal-operator-crds-and-rbac/kustomization.yaml` override each binding's `subjects` list to `[{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}]`. Mirrors the idiom already used in the sibling `remote/upstream/webhook-injector-rbac/` subtree.
- Reason: The helm chart's fullname-templated SA + binding names render consistent across the SA itself and the binding subjects; the kustomize port consumes upstream verbatim and so loses this consistency. Targeted subject patches are the minimal correct fix — `namePrefix:` would also rename the CRDs and break the manager's CRD watches.
- Impact: The unprefixed `controller-manager` SA from upstream stays in the build output but unused (the manager authenticates as the Gardener-prefixed SA via remote-kubeconfig). A TEST-PHASE block currently in `cc/kube-secrets//values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/remote/kustomization.yaml` carrying the same three patches becomes redundant once this lands, and is removed in a cc/kube-secrets follow-up commit.

## Capabilities

### New Capabilities

None. This change modifies existing capabilities; no new capabilities are introduced.

### Modified Capabilities

- `kustomize-resource-splitting`: REMOVE the "Remote resources pre-rendered as ManagedResource wrappers" requirement and the "Role to ClusterRole conversion" scenario. ADD requirements for "Two cluster-targeted kustomize roots produce direct-apply YAML (no MR)", "Apply pipeline targets kube-secrets per-cluster overlays", "Build via kustomize Git URL ref consumes upstream live (no committed pre-renders)", "Workerless webhooks consume only upstream's VWC manifest", "Webhook delivery via Service→URL rewrite at admission time", "Host webhook Service exposes admission webhook server port". MODIFY existing equivalence and resource-categorization requirements to drop ManagedResource scenarios.
- `kustomize-sidecar-injection`: REMOVE the sidecar's webhook-config push-role requirements (the "Sidecar args match current configuration" scenario and the local `webhook-config` ConfigMap dependency). ADD requirements for "Webhook-injector sidecar configured for patch mode with admission-webhook bootstrap", "Webhook-injector admission webhook bootstrapped on workerless cluster", "Workerless ValidatingWebhookConfiguration labeled for webhook-injector patch-mode selection", "Webhook-injector ServiceAccount granted target-cluster RBAC for patch mode + admission bootstrap". MODIFY removability and image-tag-override scenarios to clarify they apply in the new mode.
- `webhook-url-rendering`: OBSOLETE. The capability's previous requirements ("Pre-rendered webhook manifests checked into repository", "Regeneration Makefile target for upstream upgrades", "Webhook configurations transformed from service-based to URL-based") are all REMOVED — the URL rewrite happens at admission time on the workerless cluster (governed by the new requirements in `kustomize-resource-splitting` and `kustomize-sidecar-injection`), not at build time.

## Impact

**This repo (`sapcc/helm-charts`)**:
- `system/kustomize/metal-operator-remote/` restructured: consolidated `host/base/manager-patch.yaml`; `host/base/webhook-service.yaml` exposes a second `admission: 9444` port; `remote/upstream/metal-operator-webhooks/` simplified to a single `kustomization.yaml` consuming upstream's `manifests.yaml` via raw GitHub URL with a label patch; `components/webhook-injector/sidecar.yaml` configured for PR-10-v2 patch mode with admission-webhook bootstrap (4 new flags: `--external-host`, `--external-port`, `--admission-webhook-name`, `--admission-external-port` + admission containerPort)
- Deletions: `remote/upstream/metal-operator-crds-and-rbac/managedresources.yaml`, `remote/upstream/metal-operator-webhooks/managedresources.yaml`, `remote/upstream/metal-operator-webhooks/manifests-url-based.yaml`, `remote/upstream/metal-operator-webhooks/upstream-no-svc/`, `remote/upstream/metal-operator-webhooks/system-namespace.yaml`, `remote/upstream/metal-operator-webhooks/webhook-service-stub.yaml`, `host/base/webhook-config.yaml`, `scripts/wrap-managedresources.sh`
- `system/Makefile` targets `regen-metal-operator-remote-{crds,webhooks}` deleted along with their helper variables
- 3 capability specs in `openspec/specs/` modified (no new capabilities)

**Coordinated changes outside this repo**:
- **`cc/kube-secrets`**: Per-cluster overlay layout requires a parallel `host/` + `remote/` subpath structure under `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`; the Concourse pipeline definition for the dual-step apply must live there; the `cluster-overlay-layout` capability spec needs an update. **Two additional coordination items for PR-10-v2 patch mode + admission-webhook bootstrap** (see tasks.md Section 16.14): (a) widen remote-kubeconfig RBAC to include `mutatingwebhookconfigurations` `create,get,list,watch,update,patch` (recommended via consumption of upstream `webhook-injector//config/rbac.yaml` ClusterRole `webhook-injector-target`, overriding only the binding subjects); (b) add Concourse pipeline gate task between `host/` apply and `remote/` apply that polls for the bootstrapped `metal-operator-webhook-injector-mutator` MWC on the workerless cluster (`kubectl wait --for=jsonpath='{.metadata.name}'=metal-operator-webhook-injector-mutator`). **This change must be tracked with OpenSpec in `cc/kube-secrets`** as the second half of a coordinated two-repo change (parallel to the previous `move-cluster-overlays-to-kube-secrets` change).
- **`SAP-cloud-infrastructure/webhook-injector`** (SAP-internal binary): Needs PR-10-v2 patch mode with admission-webhook bootstrap (label-based webhook selection, `--external-host`/`--external-port`/`--admission-external-port` flags, `metal-operator-webhook-injector-mutator` MWC bootstrap on the workerless cluster). **Tracked at [SAP-cloud-infrastructure/webhook-injector#10](https://github.com/SAP-cloud-infrastructure/webhook-injector/pull/10)**. The new mode must be available in the published webhook-injector image before this change can ship to production.

**Tracking**:
- Implements parent epic [`cc/unified-kubernetes#831`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/831) ("Refactor deployment automation for split host/remote cluster setup")
- Continues the work of archived POC change `2026-05-13-poc-kustomize-metal-operator-remote` (tracked as `cc/unified-kubernetes#1169`)
- Webhook-injector context per `cc/unified-kubernetes#914`
- Scope is **metal-operator-remote only**; other operators in #831 (boot, ipam, argora, khalkeon) adopt the same pattern in follow-up changes

**Out of scope (explicitly deferred)**:
- Structured-auth migration (replacing Gardener-managed token Secrets `remote-serviceaccount-secret.yaml` and `rotate-kubeconfig-secret.yaml`) — separate workstream tracked in #831's "Solved" section
- Multi-operator generalization (extracting reusable scaffolding for boot/ipam/argora/khalkeon) — premature abstraction; deferred to whichever change tackles operator #2
- cert-manager-based TLS for the webhook server — webhook-injector self-signed cert/CA continues to be the source per #831's "Solved" section

**No runtime changes**: the controller pod's behavior, RBAC needs, image, args, env vars, volumes, network connectivity, leader election, and webhook handling are all unchanged. This is a deployment-mechanism restructure only.
