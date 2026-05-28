# metal-operator-remote (Kustomize)

Kustomize-based deployment of the metal-operator in a split host/remote cluster setup. Replaces the previous Helm chart at `system/metal-operator-remote/` and the previous Helm-based pipeline that used ManagedResource secrets to deliver remote content.

This repository owns only the **bases and components**. Per-cluster overlays live in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets) and reference these bases via kustomize Git URL refs (`?ref=master`). See [Per-cluster overlays](#per-cluster-overlays).

## Cluster terminology

This kustomize tree uses two cluster-role-neutral directory names. Their
meaning in our deployment topology:

| Directory | Meaning | Gardener equivalent |
|---|---|---|
| `host/` | **Workload cluster** — where the metal-operator controller pod actually runs (and where webhook callbacks land) | seed |
| `remote/` | **Workerless cluster** — API server only, no nodes; receives CRDs, RBAC, the ValidatingWebhookConfiguration, and supporting Namespaces (`metal-servers` for user-facing CRs, `system` for the webhook-service ExternalName) | shoot |

The workerless cluster's API server pod runs on the host cluster (Gardener-shoot
topology; also kcp / vCluster). This co-location is what makes the
ExternalName-based webhook routing work — see the [Webhook routing](#webhook-routing) section.

## Dual-kustomize apply model

There are two independent kustomize roots, applied to two different clusters:

```
host/base/   →  kubectl apply --kubeconfig=<workload-cluster>   → Deployment, Services, Ingress, Secrets, RBAC, sidecar
remote/      →  kubectl apply --kubeconfig=<workerless-cluster> → CRDs, RBAC, Namespaces, ValidatingWebhookConfiguration, ExternalName Service
```

The deployment pipeline (a two-step Concourse pipeline that applies the host root then the remote root with the matching kubeconfig for each cluster) lives in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets), not in this repository.

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
│   ├── kustomization.yaml          # composes upstream/crds-and-rbac + upstream/webhooks + custom/base
│   ├── upstream/
│   │   ├── crds-and-rbac/
│   │   │   └── kustomization.yaml  # references upstream config/{crd,rbac} via Git URL ref
│   │   └── webhooks/
│   │       ├── kustomization.yaml          # OUTER LAYER: composes upstream-no-svc + namespace + ExternalName
│   │       ├── upstream-no-svc/
│   │       │   └── kustomization.yaml      # INNER LAYER: pulls upstream config/webhook + $patch:delete on Service
│   │       ├── system-namespace.yaml       # creates Namespace "system" on workerless
│   │       └── webhook-service-stub.yaml   # ExternalName Service: webhook-service/system → metal-operator-webhook-service
│   └── custom/                     # Namespace metal-servers + custom RBAC + prod/qa Components
│       ├── base/
│       └── components/
│           ├── prod/
│           └── qa/
└── components/
    └── webhook-injector/           # Reusable sidecar Component (ca-rotation mode)
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

The workerless cluster's `ValidatingWebhookConfiguration` uses upstream's
verbatim `clientConfig.service: { name: webhook-service, namespace: system }`
form (no URL rewrite). When the workerless API server invokes a webhook,
resolution goes:

1. API server queries its own etcd: "Is there a Service `webhook-service`
   in namespace `system`?" Finds the **ExternalName** Service we deploy
   via `remote/upstream/webhooks/webhook-service-stub.yaml`.
2. Reads `spec.externalName: metal-operator-webhook-service` (short name,
   identical for all clusters — no per-cluster customization).
3. Resolves the short name via the API server pod's `/etc/resolv.conf`
   search paths to the host cluster's actual `metal-operator-webhook-service`
   ClusterIP (which kube-proxy routes to the controller pod's webhook
   server).

This works because the workerless API server pod lives in the same
Gardener-managed seed namespace as the metal-operator controller pod.
Mirrors the pattern of the previous Helm-based pipeline (which used a
pre-rendered URL `https://metal-operator-webhook-service:443/...`) — same
DNS-search-path mechanism, just expressed in `clientConfig.service` form
instead of `clientConfig.url` form.

No URL rewrite happens at any layer (build time, deploy time, or runtime).
Upstream's webhook config is delivered verbatim except for the
`$patch: delete` on upstream's regular Service (which would otherwise
conflict with our ExternalName Service). The `caBundle` field is populated
at runtime by the [webhook-injector sidecar](#webhook-injector-sidecar)
running alongside the controller pod, in `ca-rotation` mode.

## Webhook-injector sidecar

The host-side controller `Deployment` includes a `webhook-injector` sidecar
(see `components/webhook-injector/`). In `ca-rotation` mode, the sidecar:

- watches the cert-manager-issued certificate Secret on the host cluster,
- patches `spec.webhooks[*].clientConfig.caBundle` on the workerless cluster's
  `ValidatingWebhookConfiguration` whenever the cert rotates,
- uses RBAC scoped to `get` and `patch` on
  `validatingwebhookconfigurations.admissionregistration.k8s.io` only.

Cross-reference:
[SAP-cloud-infrastructure/webhook-injector#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9).

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
#    - remote/upstream/crds-and-rbac/kustomization.yaml
#    - remote/upstream/webhooks/upstream-no-svc/kustomization.yaml

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
| `remote/upstream/crds-and-rbac/managedresources.yaml` (pre-rendered) | Live `kustomize build` of `remote/upstream/crds-and-rbac/` (Git URL ref to upstream `config/{crd,rbac}`) |
| `remote/upstream/webhooks/managedresources.yaml` (pre-rendered) | Two-layer kustomize at `remote/upstream/webhooks/` — outer composes namespace + ExternalName Service stub + inner; inner pulls upstream `config/webhook` and `$patch: delete`s the regular Service |
| `remote/upstream/webhooks/manifests-url-based.yaml` (pre-rendered URL-form webhook config) | The workerless `ValidatingWebhookConfiguration` keeps upstream's `clientConfig.service` form; cross-cluster routing is handled by the ExternalName Service in namespace `system` (see [Webhook routing](#webhook-routing)) |
| `host/base/webhook-config.yaml` (host-side ConfigMap consumed by an old webhook-injector mode) | The webhook-injector sidecar runs in `ca-rotation` mode and references the workerless `ValidatingWebhookConfiguration` directly (no host-side ConfigMap) |
| `host/base/manager-remote-patch.yaml` + `host/base/manager-webhook-patch.yaml` | Consolidated `host/base/manager-patch.yaml` (single source for env, volumes, args, sidecar) |
| `Role → ClusterRole` and `RoleBinding → ClusterRoleBinding` conversion patches in `remote/upstream/crds-and-rbac/` | Removed — the workerless cluster receives upstream RBAC verbatim |
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
  │            kubectl apply (Step 2) → Deployment, Services, Ingress,
  │            Secrets, RBAC, webhook-injector sidecar
  │
  └─ remote/ → Workerless cluster (shoot, API-server-only):
               kubectl apply (Step 1) → CRDs, RBAC, Namespaces,
               ValidatingWebhookConfiguration, ExternalName Service stub
```

The workerless cluster is API-server-only (no nodes). The metal-operator
controller runs in the workload cluster and reconciles resources in the
workerless API server. Webhooks land back at the controller pod via the
ExternalName Service routing described in [Webhook routing](#webhook-routing).

## Troubleshooting

**`kustomize build` fails with "resource not found"**
- Check that the `?ref=` tag in `kustomization.yaml` points to a valid upstream git tag
- Verify network access to `github.com/ironcore-dev/metal-operator`

**Role→ClusterRole patch missing / RBAC mismatch**
- This change removed the conversion patches deliberately. The workerless
  cluster receives upstream Roles/RoleBindings as-is. If a controller
  needs cluster-scoped permissions, add them in `remote/custom/base/`
  (not via patches on upstream).

**Webhook calls fail with "no endpoints for service"**
- Verify the ExternalName Service `webhook-service` exists in namespace
  `system` on the workerless cluster: `kubectl get svc -n system webhook-service`
- Verify the host-side `metal-operator-webhook-service` ClusterIP exists
  and routes to the controller pod
- Verify the workerless API server pod and the controller pod are co-located
  in the same seed namespace (DNS search paths must resolve the short name)

**`kube-secrets` overlay fails with "new root cannot be absolute"**
- You probably tried to substitute github.com URLs with absolute filesystem paths during local validation. kustomize requires **relative** paths in `resources:` entries. Use `os.path.relpath` (Python) or compute the right number of `..` levels manually, and build with `kustomize build --load-restrictor=LoadRestrictionsNone`. See the kube-secrets `values/kustomize/README.md` for the correct local-validation recipe.
