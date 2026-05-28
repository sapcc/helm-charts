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
- To: Upstream's service-based webhook config (`clientConfig.service: webhook-service/system`) is applied directly to workerless via the `remote/` kustomize tree using a two-layer structure (inner layer pulls upstream and removes the regular ClusterIP Service via `$patch: delete`; outer layer adds an `ExternalName` Service named `webhook-service` in a new `system` namespace pointing to `metal-operator-webhook-service` short name); webhook-injector sidecar narrows to TLS cert + caBundle rotation only
- Reason: No URL rewrite step needed; the `ExternalName` indirection bypasses the workerless cluster's lack of kube-proxy; upstream-tracking is automatic via Git URL ref
- Impact: Workerless cluster gets a new `system` Namespace + `webhook-service` ExternalName Service; the local `webhook-config` ConfigMap on host is deleted; **webhook-injector binary needs a `WEBHOOK_INJECTOR_MODE=ca-rotation` mode** (out-of-repo dependency — see Impact)

**Role → ClusterRole conversion**
- From: `remote/upstream/crds-and-rbac/kustomization.yaml` patches upstream's `kind: Role` and `kind: RoleBinding` to `kind: ClusterRole` and `kind: ClusterRoleBinding` (introduced during the kustomize POC as a defensive measure)
- To: Upstream RBAC applied verbatim — Roles stay Roles, RoleBindings stay RoleBindings
- Reason: This was a `ManagedResource`-era workaround for GRM's namespace handling; the helm chart's bundled `managedresources/crds-and-rbac.yaml` proves un-converted Roles work in production
- Impact: Workerless cluster's RBAC layout changes shape (some leader-election roles return to namespace scope) but functional behavior matches the helm-deployed clusters

**Manager Deployment patches**
- From: Two patch files (`manager-remote-patch.yaml`, `manager-webhook-patch.yaml`); SAP-specific manager `args` (6 flags including `--mac-prefixes-file`, `--probe-image`, `--registry-url`, `--manager-namespace`) missing from the kustomize tree (only `--leader-elect` from upstream)
- To: Single consolidated `host/base/manager-patch.yaml` containing all manager Deployment customizations including the 6 restored args
- Reason: Closes a deploy-readiness gap from the kustomize POC where the args were only in helm's `values-overrides.yaml`; consolidates patch surface for review clarity
- Impact: Kustomize tree is end-to-end deploy-ready; `manager-webhook-patch.yaml`'s historical mixing of webhook concerns and macdb is resolved

## Capabilities

### New Capabilities

None. This change modifies existing capabilities; no new capabilities are introduced.

### Modified Capabilities

- `kustomize-resource-splitting`: REMOVE the "Remote resources pre-rendered as ManagedResource wrappers" requirement and the "Role to ClusterRole conversion" scenario. ADD requirements for "Two cluster-targeted kustomize roots produce direct-apply YAML (no MR)", "Sequential apply order remote → host", "Build via kustomize Git URL ref consumes upstream live (no committed pre-renders)", "Workerless cluster receives `system` Namespace + `webhook-service` ExternalName Service for upstream webhook config compatibility", "Webhook delivery via ExternalName routing (no URL rewrite, no local ConfigMap on host)". MODIFY existing equivalence and resource-categorization requirements to drop ManagedResource scenarios.
- `kustomize-sidecar-injection`: REMOVE the sidecar's webhook-config push-role requirements (the "Sidecar args match current configuration" scenario and the local `webhook-config` ConfigMap dependency). ADD requirements for "Sidecar runs in caBundle-rotation mode", "Sidecar manages TLS cert lifecycle for `metal-operator-webhook-service` on host", "Sidecar patches caBundle field of named workerless WebhookConfiguration via remote-kubeconfig", "Sidecar RBAC on remote scoped to `get` + `patch` on `webhooks[*].clientConfig.caBundle` only". MODIFY removability and image-tag-override scenarios to clarify they apply in the new mode.
- `webhook-url-rendering`: OBSOLETE in its current form. The capability either gets DELETED entirely (no URL rewrite happens anymore — `ExternalName` routing is governed by the new requirements in `kustomize-resource-splitting`) or RENAMED to `webhook-routing-via-externalname` to govern the new mechanism specifically. Decision belongs in the specs phase; flagged as Open Question.

## Impact

**This repo (`sapcc/helm-charts`)**:
- `system/kustomize/metal-operator-remote/` restructured: consolidated `host/base/manager-patch.yaml`; new two-layer `remote/upstream/webhooks/` (inner `upstream-no-svc/` removes upstream Service, outer adds `system-namespace.yaml` + `webhook-service-stub.yaml`); narrowed `components/webhook-injector/`
- Deletions: `remote/upstream/crds-and-rbac/managedresources.yaml`, `remote/upstream/webhooks/managedresources.yaml`, `remote/upstream/webhooks/manifests-url-based.yaml`, `host/base/webhook-config.yaml`, `scripts/wrap-managedresources.sh`
- `system/Makefile` targets `regen-metal-operator-remote-{crds,webhooks}` deleted along with their helper variables
- 3 capability specs in `openspec/specs/` modified (no new capabilities)

**Coordinated changes outside this repo**:
- **`cc/kube-secrets`**: Per-cluster overlay layout requires a parallel `host/` + `remote/` subpath structure under `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`; the Concourse pipeline definition for the dual-step apply must live there; the `cluster-overlay-layout` capability spec needs an update. **This change must be tracked with OpenSpec in `cc/kube-secrets`** as the second half of a coordinated two-repo change (parallel to the previous `move-cluster-overlays-to-kube-secrets` change).
- **`SAP-cloud-infrastructure/webhook-injector`** (SAP-internal binary): Needs a new mode `WEBHOOK_INJECTOR_MODE=ca-rotation` (or equivalent flag) where `--webhook-config-name` references the workerless `ValidatingWebhookConfiguration` to patch caBundle into, with the local-ConfigMap read path bypassed. **Tracked at [SAP-cloud-infrastructure/webhook-injector#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9)**. The new mode must be available in the published webhook-injector image before this change can ship to production.

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
