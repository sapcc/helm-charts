# metal-operator-remote (Kustomize)

Kustomize-based deployment of the metal-operator in a split host/remote cluster setup. Replaces the previous Helm chart at `system/metal-operator-remote/` and the previous Helm-based pipeline that used ManagedResource secrets to deliver remote content.

This repository owns only the **bases and components**. Per-cluster overlays live in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets) and reference these bases via kustomize Git URL refs (`?ref=master`). See [Per-cluster overlays](#per-cluster-overlays).

## Cluster terminology

This kustomize tree uses two cluster-role-neutral directory names. Their
meaning in our deployment topology:

| Directory | Meaning | Gardener equivalent |
|---|---|---|
| `host/` | **Workload cluster** — where the metal-operator controller pod actually runs (and where webhook callbacks land) | seed |
| `remote/` | **Workerless cluster** — API server only, no nodes; receives CRDs, RBAC, the `ValidatingWebhookConfiguration`, and the `metal-servers` user-facing CR landing namespace | shoot |

The workerless cluster's API server pod runs on the host cluster (Gardener-shoot
topology; also kcp / vCluster). This co-location is what lets webhook callbacks
reach the host-cluster Service `metal-operator-webhook-service` via host-cluster
CoreDNS — see the [Webhook routing](#webhook-routing) section.

## Dual-kustomize apply model

There are two independent kustomize roots, applied to two different clusters:

```
host/base/   →  kubectl apply --kubeconfig=<workload-cluster>   → Deployment, Services (incl. admission port), Ingress, Secrets, RBAC, sidecar
remote/      →  kubectl apply --kubeconfig=<workerless-cluster> → CRDs, RBAC, Namespaces, ValidatingWebhookConfiguration
```

The deployment pipeline (two independent `kubectl apply -k` invocations against the matching kubeconfig for each cluster) lives in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets), not in this repository. **On a fresh install** the pipeline MUST apply `host/` first and wait for the webhook-injector sidecar to bootstrap the `metal-operator-webhook-injector-mutator` MutatingWebhookConfiguration on the workerless cluster before applying `remote/` — otherwise the metal3 VWC enters the workerless API server in Service form referencing a non-existent Service, and `failurePolicy: Fail` × 7 webhook entries blocks all metal3 CRD writes until the periodic reconciler recovers (up to one `--sync-period`). See the [bootstrap-window note](#bootstrap-window) below for the gate-task pattern. On steady-state re-applies, ordering is irrelevant (admission rewrites Service → URL idempotently).

## Prerequisites

- `kustomize` v5+ (for `patches[].target.kind` matching)
- `kubectl` (for verification)

## Directory Layout

```
.
├── host/                           # APPLIED TO HOST (workload cluster, Step 2)
│   └── base/                       # Shared host-side resources for all environments
│       ├── kustomization.yaml      # references upstream config/manager via Git URL ref
│       ├── manager-patch.yaml      # consolidated controller-manager patch (env, volumes, args, sidecar)
│       └── ...                     # Services, Ingress, Secrets, RBAC, NetworkPolicy
├── remote/                         # APPLIED TO REMOTE (workerless cluster, Step 1)
│   ├── kustomization.yaml          # composes upstream/metal-operator-crds-and-rbac + upstream/metal-operator-webhooks + custom/base
│   ├── upstream/
│   │   ├── crds-and-rbac/
│   │   │   └── kustomization.yaml  # references upstream config/{crd,rbac} via Git URL ref
│   │   └── webhooks/
│   │       └── kustomization.yaml  # pulls upstream config/webhook/manifests.yaml (single file via raw URL) + management-label patch on the VWC
│   └── custom/                     # Namespace metal-servers + custom RBAC + prod/qa Components
│       ├── base/
│       └── components/
│           ├── prod/
│           └── qa/
└── components/
    └── webhook-injector/           # Reusable sidecar Component (PR-10-v2 patch mode + admission-webhook bootstrap)
```

Per-cluster overlays are **not** in this repository — they live in `cc/kube-secrets` (see [Per-cluster overlays](#per-cluster-overlays)).

## Per-cluster overlays

Per-cluster overlays for `metal-operator-remote` live in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets) under
`values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`.

They reference the bases in this repository via kustomize Git URL refs:

```yaml
# Example overlay kustomization.yaml in cc/kube-secrets:
resources:
  - https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/host/base?ref=master
```

Production overlays MUST track `?ref=master`. Test/scratch overlays may temporarily reference a feature branch with a `# TEST-PHASE: tracking <branch>` comment, but MUST be reverted to `master` before merge. See the `cluster-overlay-layout` capability spec in `cc/kube-secrets` for the full requirements.

### Adding a new cluster

Add a new directory in `cc/kube-secrets` at:
`values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`
with the appropriate `kustomization.yaml`, `host/`, and `remote/` subdirectories.
**No change to this repository is required for cluster onboarding.**

### Updating bases

Changes to `host/base/`, `remote/`, or components in this repository are picked up automatically by kube-secrets overlays at the next `kustomize build` (since they track `?ref=master`). Apply normal change-management in this repository (PR review, OpenSpec change for spec-level requirements).

Tracking: [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169)

## Webhook routing

The workerless cluster's `ValidatingWebhookConfiguration` is shipped (in git)
in upstream's verbatim `clientConfig.service: { name: webhook-service, namespace: system, path: /<…> }`
form. **The Service form is a placeholder.** At runtime, the webhook-injector
sidecar's bootstrapped `metal-operator-webhook-injector-mutator` admission
webhook intercepts every CREATE/UPDATE on the labeled VWC and rewrites
`clientConfig.Service` → `clientConfig.URL = https://metal-operator-webhook-service:443/<path>`
synchronously **before validation**. The workerless API server therefore only
ever **stores** URL form, and webhook callbacks dial the host-cluster Service
directly.

```
              build-time manifest                       stored in workerless etcd
              ──────────────────────                    ──────────────────────────
              clientConfig:                             clientConfig:
                service:                                  url: https://metal-operator-webhook-service:443/<path>
                  name: webhook-service                   caBundle: <base64 cert>
                  namespace: system
                  path: /<path>
                                       ↓ admission ↓
                            (metal-operator-webhook-injector-mutator
                             rewrites Service → URL on every apply)
```

The hostname `metal-operator-webhook-service` resolves from the workerless API
server pod via the host-cluster CoreDNS (`/etc/resolv.conf` search paths),
because the workerless API server pod runs in the host cluster (Gardener seed)
alongside the metal-operator controller pod.

**Why admission rewrite, not ExternalName or build-time URL render:** Earlier
designs used either a pre-rendered URL form or an ExternalName Service stub in
a workerless `system` namespace. Both approaches were discarded: pre-rendered
URLs require a regen + commit cycle on every upstream version bump; ExternalName
for webhook clientConfig is rejected by Gardener's default `--enable-aggregator-routing=true`
([k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659)). Admission rewrite
is GitOps-safe (re-applies are idempotent because admission runs before
validation, sanitizing the K8s 3-way-merge re-introduction of the Service field
in-flight), tracks upstream automatically (no rewrite at build time), and
sidesteps the aggregator-routing limitation. See `openspec/changes/replace-managedresource-with-dual-kustomize/design.md`,
section "Why admission-webhook bootstrap, not ExternalName" for the full
rationale and code-level references.

The `caBundle` field is also populated by the same sidecar (and refreshed
periodically as the cert rotates).

### Bootstrap window

On a **fresh install** of a new workerless cluster, the admission webhook does
not yet exist on the workerless API server when `remote/` is applied for the
first time. If `remote/` lands before the sidecar has bootstrapped its
`metal-operator-webhook-injector-mutator` MWC, the metal3 VWC enters the
apiserver in Service form pointing at a non-existent Service. With upstream's
`failurePolicy: Fail` × 7 webhook entries (BiosSettings, BiosVersion, BmcSecret,
BmcSettings, BmcVersion, Endpoint, Server), all metal3 CRD writes are blocked
until the sidecar's periodic reconciler recovers (up to one `--sync-period`).
This is non-catastrophic (auto-recovery) but ugly. Mitigation lives in the
Concourse pipeline (`cc/kube-secrets`): a gate task between the host/ apply and
remote/ apply that waits for the bootstrapped MWC:

```bash
kubectl --kubeconfig=$REMOTE_KUBECONFIG \
  wait --for=jsonpath='{.metadata.name}'=metal-operator-webhook-injector-mutator \
  mutatingwebhookconfiguration/metal-operator-webhook-injector-mutator \
  --timeout=5m
```

The gate is idempotent (instant return on subsequent runs once the MWC exists).

## Webhook-injector sidecar

The host-side controller `Deployment` includes a `webhook-injector` sidecar
(see `components/webhook-injector/`). It runs in **PR-10-v2 patch mode with
admission-webhook bootstrap**, with three runtime responsibilities:

1. **Bootstrap** the `metal-operator-webhook-injector-mutator` MutatingWebhookConfiguration
   on the workerless cluster (via the remote-kubeconfig). This MWC selects
   labeled MWC/VWC/CRD resources by `webhook-injector.cloud.sap/managed=true`
   and routes admission to the sidecar's in-pod admission server at
   `https://metal-operator-webhook-service:9444/mutate-{mwc,vwc,crd}`.
2. **Periodically reconcile** labeled webhook configs on the workerless cluster
   — refresh `caBundle`, rewrite `clientConfig.Service` → `clientConfig.URL`,
   restamp on cert rotation. This loop is the drift safety net; the admission
   webhook is the primary mechanism.
3. **Serve admission requests** on port `9444` (in-pod). The host-side Service
   `metal-operator-webhook-service` exposes this as a second named port
   (`admission: 9444 → 9444`, alongside the existing `webhook: 443 → 9443`),
   reachable from the workerless API server pod via host-cluster CoreDNS.

The sidecar manages a self-signed TLS serving cert/CA for `metal-operator-webhook-service`
on the host cluster (cert-manager is explicitly out of scope — the sidecar
remains the self-signed cert/CA source).

Required RBAC on the workerless cluster (delivered via remote-kubeconfig in
`cc/kube-secrets`): `mutatingwebhookconfigurations` `create,get,list,watch,update,patch`
(needed for bootstrap), `validatingwebhookconfigurations` `get,list,watch,update,patch`
(periodic reconcile), `customresourcedefinitions` `get,list,watch,update,patch`
(harmless for our use case where no CRDs carry the management label, but
included via upstream's canonical ClusterRole `webhook-injector-target`).

Cross-reference:
[SAP-cloud-infrastructure/webhook-injector#10](https://github.com/SAP-cloud-infrastructure/webhook-injector/pull/10).

## Common Tasks

### Preview a base or component

```bash
# Host base (deployment, services, ingress template, etc.)
kustomize build system/kustomize/metal-operator-remote/host/base/

# Remote root (resources sent to the workerless API server)
kustomize build system/kustomize/metal-operator-remote/remote/
```

To preview a complete cluster overlay (host + remote combined), build it from `cc/kube-secrets`:

```bash
kustomize build <kube-secrets-checkout>/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/
```

### Upgrade upstream metal-operator version

When a new version of `ironcore-dev/metal-operator` is released, edit the
pinned tag in three `kustomization.yaml` files:

```bash
# 1. Edit ?ref=v0.4.0 → ?ref=v<NEW> in:
#    - host/base/kustomization.yaml
#    - remote/upstream/metal-operator-crds-and-rbac/kustomization.yaml
#    - remote/upstream/metal-operator-webhooks/kustomization.yaml  (raw.githubusercontent.com URL — pin tag in path, not ?ref)

# 2. Verify the build still succeeds:
kustomize build system/kustomize/metal-operator-remote/host/base/  > /dev/null && echo OK
kustomize build system/kustomize/metal-operator-remote/remote/     > /dev/null && echo OK

# 3. Diff against the previous tag for review:
git diff -- system/kustomize/metal-operator-remote/

# 4. Commit:
git add system/kustomize/metal-operator-remote/
git commit -m "chore(metal-operator-remote): bump upstream to v<NEW>"
```

No regeneration script, no Makefile target — the kustomize Git URL refs
pull upstream content live at every `kustomize build`.

Per-cluster image tags (controller, webhook-injector) are pinned in the kube-secrets overlays — update them there if needed, not here. See `cc/kube-secrets/values/kustomize/.../metal-operator-remote/host/kustomization.yaml`.

## Removed in 2026-05

The dual-kustomize restructure (`replace-managedresource-with-dual-kustomize`)
removed the previous ManagedResource-based delivery pipeline. The following
artifacts and mechanisms no longer exist; their replacements are listed below.

| Removed | Replacement |
|---|---|
| `scripts/wrap-managedresources.sh` (base64-wrapping rendered YAML into ManagedResource Secret payloads) | Direct `kubectl apply` of `kustomize build remote/` against the workerless cluster |
| `remote/upstream/metal-operator-crds-and-rbac/managedresources.yaml` (pre-rendered) | Live `kustomize build` of `remote/upstream/metal-operator-crds-and-rbac/` (Git URL ref to upstream `config/{crd,rbac}`) |
| `remote/upstream/metal-operator-webhooks/managedresources.yaml` (pre-rendered) | Single `remote/upstream/metal-operator-webhooks/kustomization.yaml` that pulls upstream's `manifests.yaml` (the VWC) directly via `raw.githubusercontent.com` URL pinned to a tag, plus a kustomize patch that adds the `webhook-injector.cloud.sap/managed: "true"` label so the webhook-injector sidecar selects it |
| `remote/upstream/metal-operator-webhooks/manifests-url-based.yaml` (pre-rendered URL-form webhook config) | The workerless `ValidatingWebhookConfiguration` ships in upstream's `clientConfig.service` form; the URL form is materialized at admission time by the webhook-injector sidecar's bootstrapped `metal-operator-webhook-injector-mutator` MWC (see [Webhook routing](#webhook-routing)) |
| `host/base/webhook-config.yaml` (host-side ConfigMap consumed by an old webhook-injector mode) | The webhook-injector sidecar runs in PR-10-v2 patch mode with admission-webhook bootstrap; it selects labeled webhook configs on the workerless cluster directly via `--webhook-label` (no host-side ConfigMap) |
| `host/base/manager-remote-patch.yaml` + `host/base/manager-webhook-patch.yaml` | Consolidated `host/base/manager-patch.yaml` (single source for env, volumes, args, sidecar) |
| `Role → ClusterRole` and `RoleBinding → ClusterRoleBinding` conversion patches in `remote/upstream/metal-operator-crds-and-rbac/` | Removed — the workerless cluster receives upstream RBAC verbatim |
| `make regen-metal-operator-remote{,-crds,-webhooks}` Makefile targets | Removed — no pre-rendering step. Kustomize Git URL refs pull upstream content live at every `kustomize build` |
| `KUSTOMIZE_METAL_OPERATOR_REMOTE` variable in `system/Makefile` | Removed alongside the regen targets |

If a downstream tool or runbook references any of the removed paths, update
it to use the live `kustomize build` workflow described in
[Common Tasks](#common-tasks).

## How Deployment Works

```
cc/kube-secrets per-cluster overlay (?ref=master in helm-charts)
  │
  ├─ host/   → Workload cluster (seed):
  │            kubectl apply (Step 1) → Deployment, Services (incl. admission port),
  │            Ingress, Secrets, RBAC, webhook-injector sidecar
  │
  └─ remote/ → Workerless cluster (shoot, API-server-only):
               kubectl apply (Step 2, after gate task) → CRDs, RBAC, Namespace
               (metal-servers), ValidatingWebhookConfiguration
```

The workerless cluster is API-server-only (no nodes). The metal-operator
controller runs in the workload cluster and reconciles resources in the
workerless API server. Webhook callbacks land back at the controller pod via
`https://metal-operator-webhook-service:443/<path>` — the URL form is
materialized at admission time by the webhook-injector sidecar's bootstrapped
admission webhook (see [Webhook routing](#webhook-routing)).

## Troubleshooting

**`kustomize build` fails with "resource not found"**
- Check that the `?ref=` tag in `kustomization.yaml` points to a valid upstream git tag
- Verify network access to `github.com/ironcore-dev/metal-operator`

**Role→ClusterRole patch missing / RBAC mismatch**
- This change removed the conversion patches deliberately. The workerless
  cluster receives upstream Roles/RoleBindings as-is. If a controller
  needs cluster-scoped permissions, add them in `remote/custom/base/`
  (not via patches on upstream).

**Webhook calls fail with "no endpoints for service" or "service not found"**
- On a fresh install: did the bootstrap-window gate run? Verify the admission
  webhook exists on the workerless cluster:
  `kubectl --kubeconfig=$REMOTE_KUBECONFIG get mutatingwebhookconfiguration metal-operator-webhook-injector-mutator`
- On steady state: verify the workerless `ValidatingWebhookConfiguration` has
  URL form (admission rewrite worked):
  `kubectl --kubeconfig=$REMOTE_KUBECONFIG get validatingwebhookconfiguration validating-webhook-configuration -o yaml | grep -E 'url:|service:'`
- Verify the host-side `metal-operator-webhook-service` Service exposes both
  `webhook` (443→9443) and `admission` (9444→9444) ports, and routes to the
  controller pod
- Verify the workerless API server pod and the controller pod are co-located
  in the same seed namespace (host-cluster CoreDNS must resolve `metal-operator-webhook-service`)

**`kube-secrets` overlay fails with "new root cannot be absolute"**
- You probably tried to substitute github.com URLs with absolute filesystem paths during local validation. kustomize requires **relative** paths in `resources:` entries. Use `os.path.relpath` (Python) or compute the right number of `..` levels manually, and build with `kustomize build --load-restrictor=LoadRestrictionsNone`. See the kube-secrets `values/kustomize/README.md` for the correct local-validation recipe.
