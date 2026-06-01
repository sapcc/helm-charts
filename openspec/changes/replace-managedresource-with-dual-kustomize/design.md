# Design: replace-managedresource-with-dual-kustomize

> Pre-filled from the brainstorming session. The OpenSpec `design` artifact (when promoted via `/opsx-continue`) may extend or refine this document; the brainstorm-stage content below is the architectural foundation.

## Context

`metal-operator-remote` deploys a metal-operator controller in a split-cluster topology: the controller pod runs on a **host cluster** (= workload cluster, Gardener seed, or any platform where the workerless control plane is co-located), while the resources it reconciles (CRDs, RBAC, custom RBAC, Namespace, webhook configurations) live on a **workerless cluster** (= remote cluster, Gardener shoot, just an API server with no nodes).

Today the deployment uses Gardener's `ManagedResource` pattern: per-cluster overlays (in `cc/kube-secrets`) compose host-cluster YAML that includes `ManagedResource` + `Secret` pairs; the gardener-resource-manager (GRM) on the host cluster unwraps the Secrets and applies them to the workerless API server. Pre-rendering happens at PR time via `system/Makefile` targets that wrap upstream YAML through `scripts/wrap-managedresources.sh`, producing `managedresources.yaml` files committed to git. The webhook URL is rewritten from upstream's `clientConfig.service` form to a `clientConfig.url` form pointing at `https://metal-operator-webhook-service:443/...` — also pre-rendered at PR time.

This restructure replaces that pattern with two direct kustomize applies, eliminating the Makefile pre-rendering, the `wrap-managedresources.sh` script, the `managedresources.yaml` commit cycle, AND the webhook URL rewrite (replaced by ExternalName-based Service routing on the workerless cluster).

## Goals

| Goal | How this design satisfies it |
|---|---|
| Native pipeline (kustomize + kubectl only, no Makefile pre-renders) | Pre-render commit cycle deleted; kustomize live-builds upstream content via Git URL ref; webhook content fetched natively via `resources: <upstream Git URL>` instead of Makefile-driven URL rewrite |
| Two-step apply expectation | Step 1 = remote, Step 2 = host (sequential) |
| Portability beyond Gardener | No GRM dependency; works on any platform that co-locates the workerless API server's pod with the host cluster (e.g., Gardener-shoot, kcp, vCluster) |
| Avoid Secret-wrapping bulk | All resources applied as plain Kubernetes manifests; no base64 blobs in Secrets |
| Eliminate pre-render commit cycle | All `managedresources.yaml` committed files deleted; live build replaces them. The webhook URL rewrite (which previously required a pre-rendered file) is eliminated entirely via ExternalName-based routing. **Zero pre-rendered files** for webhook delivery. |
| Better debuggability via `kubectl diff` | Direct apply means `kubectl diff -k <overlay>` shows real drift between manifest and live state. The workerless `ValidatingWebhookConfiguration` is fully owned by the remote/ kustomize tree; drift is visible at the resource level. |
| Flux compatibility (mid-term) | Each kustomize root is consumable by one Flux `Kustomization` CR without restructuring |

## Topology

```
                   ┌─────────────────────────────────────────────┐
                   │   Concourse short-term / Flux mid-term      │
                   └───────────────┬───────────────┬─────────────┘
                                   │               │
                  Step 1           ▼               ▼          Step 2
            kubectl apply -k                  kubectl apply -k
            (remote kubeconfig)               (host kubeconfig)
                  │                                    │
                  ▼                                    ▼
   ┌─────────────────────────┐          ┌─────────────────────────┐
   │  REMOTE cluster         │  webhook │  HOST cluster           │
   │  (workerless API server,│  callback│  (workload cluster,     │
   │   running as a pod on   │ ◄────────│   seed namespace)       │
   │   the host cluster)     │  resolves│                         │
   │                         │  via     │  controller-manager Pod │
   │  Applied directly:      │ Service  │  (with webhook-injector │
   │  • CRDs                 │ ExternalN│   sidecar in caBundle-  │
   │  • ClusterRoles/Bindings│ ame      │   rotation mode)        │
   │  • ServiceAccount       │          │  metal-operator-webhook-│
   │  • custom RBAC          │          │   service (ClusterIP,   │
   │  • Namespace            │          │   selects controller pod)│
   │    "metal-servers"      │          │  remote-kubeconfig +    │
   │    (user-facing CR      │          │   secrets               │
   │     landing namespace)  │          │  RBAC, NetworkPolicy,   │
   │  • Namespace "system"   │          │   Ingress (metal-       │
   │  • Service "webhook-    │          │   registry only)        │
   │    service" in "system" │          │                         │
   │    (ExternalName \u2192      │          │   Ingress (metal-       │
   │     "metal-operator-    │          │   registry only)        │
   │     webhook-service" \u2014  │          │                         │
   │     short name,         │          │  At runtime, sidecar:   │
   │     identical for all   │          │   1. Reads/rotates TLS  │
   │     clusters)           │          │      serving cert       │
   │  • ValidatingWebhook    │          │   2. Patches caBundle   │
   │    Configuration        │          │      on workerless      │
   │    (caBundle absent;    │          │      ValidatingWebhook  │
   │     populated by sidecar│          │      Configuration      │
   │     at runtime)         │          │      (via remote-       │
   └─────────────────────────┘          │       kubeconfig,       │
                                        │       scoped to caBundle│
                                        │       field only)       │
                                        └─────────────────────────┘
```

### Webhook resolution path

When a metal-operator CR is written to the workerless API server:

```
1. Workerless API server reads ValidatingWebhookConfiguration:
     clientConfig.service:
       name: webhook-service
       namespace: system
       path: /validate-...
       (caBundle: <populated by sidecar>)

2. Workerless API server queries its OWN etcd:
     "Service webhook-service in namespace system?"
   → Finds the ExternalName Service we deployed there in step 1.

3. Reads the externalName field:
     metal-operator-webhook-service
     (short name, identical across all clusters \u2014 mirrors today's
      pre-rendered URL `https://metal-operator-webhook-service:443/...`)

4. API server pod (in shoot--<project>--<cluster> namespace on the
   seed/host cluster) resolves "metal-operator-webhook-service" via
   its /etc/resolv.conf. The pod's search paths include:
     <pod-namespace>.svc.cluster.local
     svc.cluster.local
     cluster.local
   First search path resolves the short name to the seed cluster's
   actual Service in the same Gardener-managed namespace where the
   controller pod runs.

5. Connects to seed cluster's metal-operator-webhook-service.
   This works because kube-proxy IS running on seed cluster nodes,
   so the ClusterIP routes to the controller pod's webhook server.

6. Controller pod's webhook server validates the request using
   the TLS cert managed by the sidecar (caBundle on the workerless
   webhook config matches the cert chain, so TLS verification passes).
```

Key insight: regular `clientConfig.service` lookups on a workerless cluster fail because there's no kube-proxy to route the ClusterIP. `ExternalName` Services bypass ClusterIP routing entirely — the API server reads the externalName field and resolves it via standard DNS using the API server pod's resolver, which IS the host cluster's CoreDNS (since the pod runs in the host cluster).

### Apply order: remote → host

| Phase | Cluster | What lands | Failure mode (if next phase delayed) |
|---|---|---|---|
| Step 1 | remote (workerless API server) | CRDs, ClusterRoles, ClusterRoleBindings, ServiceAccount, custom RBAC, **operator namespace `metal-servers`** (user-facing CR landing namespace), **Namespace `system`**, **`webhook-service` ExternalName Service in `system`**, **`ValidatingWebhookConfiguration` with caBundle absent** | Webhooks exist with empty caBundle → admission webhook calls fail TLS verification → metal-operator CR writes are rejected (failurePolicy=Fail). **Window is bounded and operationally benign**: the only writer to the workerless API server during cluster bootstrap is the controller, and it isn't running yet. |
| Step 2 | host (workload cluster) | controller-manager Pod + sidecar (in caBundle-rotation mode), `metal-operator-webhook-service` Service, NetworkPolicy, Ingress (metal-registry only), Secrets, RBAC | After step 2 + sidecar startup, the sidecar generates/rotates the TLS serving cert and patches `caBundle` on the workerless `ValidatingWebhookConfiguration` via remote-kubeconfig. End-to-end admission validation begins working from this point. |

### Namespace picture across the two clusters

The architecture uses several namespaces, each serving a distinct purpose. None of these are introduced by this change (except `system` on workerless for the ExternalName Service); the table documents the existing design as it stands today, plus the new `system` addition.

| Namespace | Cluster | Created by | Purpose |
|---|---|---|---|
| `metal-operator-system` | **HOST** | Implicit at deploy time: `helm install --namespace metal-operator-system` today, equivalently the per-cluster overlay's `namespace:` field for the dual-kustomize world (kube-secrets pins the namespace before applying `kustomize build` output) | Where the controller pod runs. Matches the controller's `--manager-namespace=metal-operator-system` arg (kubebuilder convention: "namespace the manager is running in"). All host-side resources without an explicit `namespace:` field land here. |
| `metal-servers` | **WORKERLESS** | `remote/custom/base/namespace.yaml` (kustomize tree); `managedresources/namespace.yaml` (helm chart) | User-facing landing namespace for **namespaced** metal-operator CRs: `BMCSecret`, `BIOSSettings`, `BIOSVersion`, `BIOSSettingsSet`, `BIOSVersionSet`, `BMCSettings`, `BMCVersion`, `BMCSettingsSet`, `BMCVersionSet`, `BMCUser`, `ServerClaim`, `ServerMaintenance`, `Endpoint`. Pre-created so operators can `kubectl create -n metal-servers …` without first creating the namespace. Note: `Server` CRs are cluster-scoped (per upstream's `+kubebuilder:resource:scope=Cluster`) and don't live in any namespace. |
| `system` | **WORKERLESS** | NEW: `remote/upstream/webhooks/system-namespace.yaml` (introduced by this change) | Holds the `webhook-service` ExternalName Service. Matches upstream's `clientConfig.service.namespace=system` placeholder — by deploying upstream's webhook config verbatim and creating this namespace + ExternalName Service, no URL rewrite is required. |
| `kube-system` | **WORKERLESS** | Pre-existing on every Kubernetes cluster | Hosts the `metal-token-rotate` ServiceAccount + Role + RoleBinding (per existing `remote/custom/base/rbac.yaml`). Used for token rotation flows. |

The host kustomize tree (`host/base/kustomization.yaml`) **does NOT pin a namespace** — it relies on the consumer (kube-secrets per-cluster overlay) to set `namespace: metal-operator-system` via its own `kustomization.yaml`. This mirrors today's helm install pattern where `--namespace=metal-operator-system` sets `.Release.Namespace` and all unscoped resources flow into it.

## Repo layout (this repo: `helm-charts`)

```
system/kustomize/metal-operator-remote/
├── host/
│   └── base/                                   # APPLIED TO HOST (Step 2)
│       ├── kustomization.yaml                  # references upstream config/manager + components/webhook-injector + top-level files
│       ├── manager-patch.yaml                  # CONSOLIDATED: all controller-manager Deployment customizations (env vars, args, volumes, ports, securityContext, network labels, serviceAccountName, hostNetwork, resources). Replaces the previous split between manager-remote-patch.yaml + manager-webhook-patch.yaml + (would-have-been) manager-args-patch.yaml. Includes the SAP-specific args restoration (closes the gap from the kustomize POC where these args were only in helm values-overrides.yaml).
│       ├── ingress.yaml                        # metal-registry Ingress only (NO new webhook Ingress)
│       ├── metal-registry-service.yaml
│       ├── webhook-service.yaml                # metal-operator-webhook-service ClusterIP — selects controller pod's webhook server
│       ├── networkpolicy.yaml                  # 5 Gardener NetworkPolicies
│       ├── remote-kubeconfig-configmap.yaml
│       ├── remote-serviceaccount-secret.yaml   # gardener-managed token Secret
│       ├── rotate-kubeconfig-secret.yaml       # gardener-managed Secret
│       └── macdb-secret.yaml
│       # NOTE: webhook-config.yaml DELETED — sidecar no longer reads webhook content from a local ConfigMap
│       # NOTE: webhook-injector-rbac.yaml MOVED into components/webhook-injector/ (see § "Webhook-injector Component encapsulation" + Section 14 of tasks.md). All sidecar-introduced host-side resources (SA + Role + RoleBinding + Pod-level serviceAccountName) live there now.
├── remote/                                     # APPLIED TO REMOTE (Step 1)
│   ├── kustomization.yaml                      # aggregates STRUCTURAL SOURCES ONLY: upstream/crds-and-rbac + upstream/webhooks + custom/base. Does NOT bind to a specific environment tier — per-environment components (prod/qa) are applied by kube-secrets per-cluster overlays based on cluster tier.
│   ├── upstream/
│   │   ├── crds-and-rbac/
│   │   │   └── kustomization.yaml              # references upstream config/crd + config/rbac via Git URL ref → plain CRDs + RBAC (no Role→ClusterRole conversion, no MR wrap)
│   │   └── webhooks/
│   │       ├── kustomization.yaml              # OUTER LAYER: references upstream-no-svc/ + system-namespace.yaml + webhook-service-stub.yaml. Composes the final webhook delivery for workerless.
│   │       ├── upstream-no-svc/                # INNER LAYER (subdirectory)
│   │       │   └── kustomization.yaml          # references upstream config/webhook directory via Git URL ref + $patch: delete on the regular Service. Output: ValidatingWebhookConfiguration only (Service removed). Two-layer structure required because kustomize loads resources before applying patches — a single-layer naive pull-and-replace would conflict on duplicate Service identifier.
│   │       ├── system-namespace.yaml           # creates Namespace "system" on the workerless cluster
│   │       └── webhook-service-stub.yaml       # ExternalName Service "webhook-service" in namespace "system" pointing to metal-operator-webhook-service (short name; identical for all clusters)
│   └── custom/
│       ├── base/
│       │   ├── namespace.yaml                  # `metal-servers` Namespace on workerless (user-facing landing for namespaced CRs)
│       │   └── rbac.yaml                       # OIDC ClusterRoleBindings (with MUST_BE_SET_IN_OVERLAY placeholders) + metal-token-rotate SA/Role/Bindings
│       └── components/
│           ├── prod/                           # patches OIDC group names to PROD values
│           └── qa/                             # patches OIDC group names to QA values
└── components/
    └── webhook-injector/                       # NARROWED to caBundle-rotation-only role (see § 4) AND now owns ALL sidecar-introduced host-side resources (see Section 14 of tasks.md)
        ├── kustomization.yaml                  # Component header + resources list (webhook-injector-rbac.yaml) + patches list (sidecar.yaml) + image override
        ├── sidecar.yaml                        # initContainer patch (caBundle-rotation mode env + args, volume mounts, probes) AND serviceAccountName override on the controller-manager Deployment (single patch, since both are sidecar-driven)
        └── webhook-injector-rbac.yaml          # SA + Role (events/secrets/leases at namespace scope) + RoleBinding for the manager Pod's SA. Originated with the sidecar feature in commit 9ffb1dc0c3 (Fabian Ruff, 2026-04-20). Encapsulating it in the Component makes enable/disable atomic.
```

### Removed

- `system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh`
- `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml`
- `system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml`
- `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml` (obsolete — kustomize live-fetches upstream `config/webhook/`)
- `system/kustomize/metal-operator-remote/host/base/webhook-config.yaml` (obsolete — sidecar no longer reads webhook content from a local ConfigMap)
- `system/Makefile` targets `regen-metal-operator-remote*` (and any helper variables)
- The `patches:` block in `remote/upstream/crds-and-rbac/kustomization.yaml` that converts upstream `Role` → `ClusterRole` and `RoleBinding` → `ClusterRoleBinding`

## Webhook delivery via ExternalName + Git URL ref

```
┌──────────────────── helm-charts ─────────────────────────────────────┐
│                                                                       │
│ remote/upstream/webhooks/upstream-no-svc/kustomization.yaml          │
│   resources:                                                          │
│     - https://github.com/ironcore-dev/metal-operator                 │
│         //config/webhook?ref=v0.4.0                                   │
│       # ↑ pulls upstream's directory (manifests.yaml + service.yaml). │
│         Tracks upstream's own kustomization.yaml \u2014 robust to upstream │
│         file renames or additions.                                    │
│   patches:                                                            │
│     - target:                                                         │
│         kind: Service                                                 │
│         name: webhook-service                                         │
│         namespace: system                                             │
│       patch: |                                                        │
│         $patch: delete                                                │
│         apiVersion: v1                                                │
│         kind: Service                                                 │
│         metadata:                                                     │
│           name: webhook-service                                       │
│           namespace: system                                           │
│       # ↑ removes upstream's regular ClusterIP Service. Output of    │
│         this layer is JUST the ValidatingWebhookConfiguration.        │
│                                                                       │
│ remote/upstream/webhooks/kustomization.yaml (outer)                   │
│   resources:                                                          │
│     - upstream-no-svc/                                                │
│       # ↑ references the inner layer's output: webhook config only.   │
│     - system-namespace.yaml                                           │
│     - webhook-service-stub.yaml                                       │
│       # ↑ OUR ExternalName Service. No identifier conflict with       │
│         upstream's Service because the inner layer already removed    │
│         it.                                                           │
│                                                                       │
│ remote/upstream/webhooks/system-namespace.yaml                       │
│   apiVersion: v1                                                      │
│   kind: Namespace                                                     │
│   metadata:                                                           │
│     name: system                                                      │
│                                                                       │
│ remote/upstream/webhooks/webhook-service-stub.yaml                   │
│   apiVersion: v1                                                      │
│   kind: Service                                                       │
│   metadata:                                                           │
│     name: webhook-service                                             │
│     namespace: system                                                 │
│   spec:                                                               │
│     type: ExternalName                                                │
│     externalName: metal-operator-webhook-service                      │
│   # ↑ short name, identical for all clusters — the API server         │
│     pod's /etc/resolv.conf search paths resolve it to the seed        │
│     cluster's actual Service in the same Gardener-managed namespace.  │
│     Mirrors today's pre-rendered URL pattern.                         │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                                ↓
                    kubectl apply -k remote/  (Step 1)
                                ↓
┌──────────────── REMOTE (workerless) cluster ──────────────────────────┐
│                                                                       │
│   Namespace: system                                                   │
│     ↳ Service: webhook-service                                        │
│         spec:                                                         │
│           type: ExternalName                                          │
│           externalName: metal-operator-webhook-service                │
│                                                                       │
│   ValidatingWebhookConfiguration (cluster-scoped)                    │
│     webhooks[*].clientConfig:                                         │
│       service:                                                        │
│         name: webhook-service                                         │
│         namespace: system                                             │
│         path: /validate-...                                           │
│       # caBundle: NOT set — sidecar populates at runtime              │
│                                                                       │
│   Namespace: metal-servers (existing)                                 │
│     ↳ user-created namespaced CRs land here:                          │
│       BMCSecret, BIOSSettings, ServerClaim, ServerMaintenance, …      │
└───────────────────────────────────────────────────────────────────────┘
                                ↓
                   kubectl apply -k host/   (Step 2)
                                ↓
┌──────────────── HOST cluster ────────────────────────────────────────┐
│                                                                       │
│   metal-operator-webhook-service ClusterIP landed                     │
│   controller-manager Pod (with webhook-injector sidecar) landed       │
│                                                                       │
│   Sidecar at runtime:                                                 │
│     1. Generates/rotates TLS serving cert for webhook-service         │
│     2. Authenticates to remote via remote-kubeconfig                  │
│     3. Patches caBundle on the workerless ValidatingWebhookConfig.    │
│        (RBAC scoped to: get + patch on webhooks[*].clientConfig.      │
│         caBundle field of named WebhookConfiguration only)            │
└───────────────────────────────────────────────────────────────────────┘
```

### Critical invariant: kustomize tree MUST NOT emit `caBundle`

The webhook-injector sidecar populates `caBundle` at runtime. Subsequent `kubectl apply -k remote/` (or Flux reconciliation) preserves the sidecar's value via `kubectl apply`'s three-way merge — but ONLY if the applied manifest never includes `caBundle`. Upstream's `config/webhook/manifests.yaml` already omits `caBundle`, so the verbatim Git URL ref is safe. Any future patch added to `remote/upstream/webhooks/` MUST NOT introduce a `caBundle` field, even an empty string — that would clobber the sidecar's value on every apply, creating a webhook-failure window.

Verifiable by `kustomize build remote/upstream/webhooks/ | yq '.. | select(.caBundle? // "missing")'` returning empty (a verify-phase test).

## Webhook-injector sidecar — narrowed to caBundle-rotation-only

| Aspect | Old | New |
|---|---|---|
| Role | Read local `webhook-config` ConfigMap → push entire `ValidatingWebhookConfiguration` to workerless via remote-kubeconfig | Manage TLS serving cert lifecycle on host + patch `caBundle` field of the named workerless `ValidatingWebhookConfiguration` |
| Local `webhook-config` ConfigMap on host | Required (source of truth) | **Deleted** — workerless kustomize root is the source of truth |
| Mode signaling | (single mode) | `WEBHOOK_INJECTOR_MODE=ca-rotation` env var (or `--mode=ca-rotation` flag) — backward compatible with push mode for any other consumers |
| `--webhook-config-name` semantics | Name of local ConfigMap on host | Name of the workerless `ValidatingWebhookConfiguration` to patch caBundle into (typically `validating-webhook-configuration` per upstream) |
| RBAC on host (host kubeconfig) | Read ConfigMap | Read TLS Secret it manages |
| RBAC on remote (via remote-kubeconfig) | Full create/update on `validatingwebhookconfigurations` and `mutatingwebhookconfigurations` | `get` + `patch` only on `webhooks[*].clientConfig.caBundle` field of named webhook configs |
| Removable per cluster | `$patch: delete` (still works) | `$patch: delete` (preserved) |
| Reconciliation cadence | Continuous (push loop) | Continuous (cert-rotation loop + caBundle reconciliation) |
| Source-of-truth for webhook content | Split: host ConfigMap + sidecar logic | Coherent: workerless `ValidatingWebhookConfiguration` (kustomize-managed) |

## Kube-secrets layout (coordinated change)

```
values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/
├── host/                                       # Step 2 target (host kubeconfig)
│   ├── kustomization.yaml                      # references helm-charts host/base via Git URL ref + cluster-specific patches
│   └── patches/                                # per-cluster: image tags, controllerManager args, NetworkPolicy CIDRs, sidecar mode + args, …
└── remote/                                     # Step 1 target (remote kubeconfig)
    ├── kustomization.yaml                      # references helm-charts remote/upstream/{crds-and-rbac,webhooks} + remote/custom + prod|qa component
    └── patches/                                # per-cluster: OIDC group via component selection (prod or qa); does NOT need to touch the workerless `webhook-service` ExternalName Service (the externalName value is the same short name `metal-operator-webhook-service` for every cluster)
```

The Concourse pipeline definition (or Flux Kustomization CRs in the mid-term) lives in the coordinated `cc/kube-secrets` change. Pipeline reads the kube-secrets per-cluster overlay and runs:

```bash
# Step 1
kustomize build .../metal-operator-remote/remote/ | \
  kubectl --kubeconfig="$REMOTE_KUBECONFIG" apply -f -

# Step 2
kustomize build .../metal-operator-remote/host/ | \
  kubectl --kubeconfig="$HOST_KUBECONFIG" apply -f -
```

### Why no per-cluster customization for the externalName

The workerless `webhook-service` ExternalName Service uses `externalName: metal-operator-webhook-service` (short name) on every cluster. This works because the workerless API server pod runs in the same Gardener-managed seed namespace as the metal-operator controller pod (e.g., both in `shoot--<project>--<cluster>`), so the API server pod's `/etc/resolv.conf` search paths resolve the short name correctly. This mirrors today's pre-rendered URL `https://metal-operator-webhook-service:443/...` which is also a short name relying on the same DNS-search-path mechanism.

## Capability spec impact

| Capability | Change summary |
|---|---|
| `kustomize-resource-splitting` | **REMOVE** "Remote resources pre-rendered as ManagedResource wrappers", "Role to ClusterRole conversion" scenario. **ADD** "Two cluster-targeted kustomize roots produce direct-apply YAML (no MR)", "Sequential apply order remote → host", "Build via kustomize Git URL ref consumes upstream live (no committed pre-renders)", "Upstream RBAC applied verbatim (no Role→ClusterRole rewrite)", "Workerless cluster receives `system` Namespace + `webhook-service` ExternalName Service for upstream webhook config compatibility", "Webhook delivery via ExternalName routing (no URL rewrite, no local ConfigMap on host)". **MODIFY** existing requirements to drop MR-related scenarios; clarify resource categorization. |
| `kustomize-sidecar-injection` | **Significant rewrite.** **REMOVE** "Sidecar args match current configuration" (push semantics), "Sidecar pushes WebhookConfiguration from local ConfigMap". **ADD** "Sidecar runs in caBundle-rotation mode (`WEBHOOK_INJECTOR_MODE=ca-rotation` or equivalent)", "Sidecar manages TLS cert lifecycle for metal-operator-webhook-service on host", "Sidecar patches caBundle field of named workerless WebhookConfiguration via remote-kubeconfig", "Sidecar RBAC on remote scoped to `get` + `patch` on `webhooks[*].clientConfig.caBundle` only", "Local `webhook-config` ConfigMap on host is not required and not deployed". **MODIFY** removability and image-tag-override scenarios (they continue to work). |
| `webhook-url-rendering` | **OBSOLETE** — capability is fully replaced by ExternalName-based routing. **DELETE** "Pre-rendered webhook manifests checked into repository", "Regeneration Makefile target for upstream upgrades", "Webhook configurations transformed from service-based to URL-based". The capability either gets removed entirely OR renamed to something like `webhook-routing-via-externalname` to govern the new mechanism. Decision belongs in the specs phase. |

## Operational notes

- **Bootstrap window**: between step 1 and step 2, the workerless cluster has CRDs and `ValidatingWebhookConfiguration` (with empty `caBundle`). Webhook callbacks fail TLS verification (failurePolicy=Fail blocks writes). The controller is the only writer; it isn't running yet, so the window is operationally benign. Once step 2 brings up the sidecar and it patches caBundle, admission validation works.
- **Drift recovery for webhook content**: the workerless `ValidatingWebhookConfiguration` is kustomize-managed. Manual edits to its `webhooks[*]` entries persist until the next `kubectl apply -k remote/` (Concourse trigger) or Flux Kustomization reconciliation. Flux's default reconciliation interval (typically 10 min) limits drift duration; Concourse-driven flows have longer drift windows tied to deploy cadence.
- **Drift recovery for caBundle**: the sidecar reconciles `caBundle` continuously. Manual edits to `caBundle` are repaired on the next sidecar reconciliation pass.
- **Cluster teardown**: when a cluster is decommissioned, `kubectl delete -k remote/` cleanly removes the workerless `ValidatingWebhookConfiguration` + `system` Namespace + ExternalName Service + CRDs + RBAC + custom RBAC + the `metal-servers` user-facing namespace. In typical operations the workerless cluster is destroyed wholesale, making this moot. The explicit teardown command is a useful runbook addition in the kube-secrets coordinated change.
- **Webhook content updates from upstream**: editing the upstream metal-operator pinned ref in `remote/upstream/webhooks/kustomization.yaml` (e.g., `?ref=v0.4.0` → `?ref=v0.5.0`) updates the workerless `ValidatingWebhookConfiguration` on the next `kubectl apply -k remote/`. No manual regeneration step. The sidecar reconciles `caBundle` against the new webhook configs automatically.
- **`caBundle` invariant** (already noted in design above): the kustomize tree MUST NOT emit `caBundle` in any webhook entry. Verify-phase test: `kustomize build remote/upstream/webhooks/ | yq '.. | select(.caBundle? // "missing")'` → empty.

## Cross-repo coordination

This change is the **first half** of a two-repo coordinated change (parallel to `move-cluster-overlays-to-kube-secrets` from 2026-05). The second half lives in `cc/kube-secrets`:

- New per-cluster overlay layout (`metal-operator-remote/host/` + `metal-operator-remote/remote/` subpaths)
- Per-cluster patches that previously lived in helm-charts overlays (now removed) and that this restructure newly requires
- Concourse pipeline definition for the dual-step apply
- Update to the `cluster-overlay-layout` capability spec in kube-secrets to formalize the dual-subpath structure

Additionally, the SAP-internal **webhook-injector binary** must be updated to expose a caBundle-rotation-only mode (`WEBHOOK_INJECTOR_MODE=ca-rotation` env var or equivalent flag). This is an out-of-repo coordinated dependency tracked at [SAP-cloud-infrastructure/webhook-injector#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9) (and surfaced in this change's brainstorm Open Questions OQ2).

## Known divergences from production helm output

A direct comparison of `kustomize build remote/` against the helm chart's `system/metal-operator-remote/build-metal-operator-remote` Makefile pipeline (see `system/metal-operator-remote/managedresources/crds-and-rbac.yaml` for the helm-rendered output) surfaces two cosmetic divergences. **Both are deferred to cutover testing for resolution** — neither is expected to be functionally consequential, but neither has been verified live.

### Divergence 1: `Role` → `ClusterRole` conversion

| Aspect | Helm chart (production today) | Our kustomize tree |
|---|---|---|
| `leader-election-role` (upstream `config/rbac/leader_election_role.yaml`) | Converted to `ClusterRole` via `sed 's/kind: Role/kind: ClusterRole/g'` | Kept as `Role` (namespace-scoped, `kube-system`) |
| `leader-election-rolebinding` | Converted to `ClusterRoleBinding` (sed catches the `kind: Role` prefix in `kind: RoleBinding`) | Kept as `RoleBinding` (`kube-system`) |
| Subject of binding | `controller-manager` SA in `system` namespace (upstream verbatim — does not match our actual SA `metal-operator-controller-manager` in `kube-system`) | Same (upstream verbatim) |

**Why probably benign**: the upstream `leader-election-rolebinding` subject doesn't match our actual SA (`metal-operator-controller-manager`) on either side, so the binding is functionally inert regardless of conversion. The manager runs without `--leader-elect` (helm's deep-merge of `values-overrides.yaml` replaces upstream args entirely with the 6 SAP args), with `replicas: 1` and `strategy: Recreate`, so leader election doesn't happen anyway. The Role/ClusterRole choice should not affect runtime behavior.

**Why kept as-is**: the design originally claimed the helm chart's bundled `managedresources/crds-and-rbac.yaml` "proves un-converted Roles work in production". On post-implementation re-inspection that file actually contains zero un-converted Roles — they're all converted. The real reason un-converted is acceptable is the binding-subject mismatch above. **Cutover testing is the verification gate.**

### Divergence 2: Webhook `clientConfig` form (URL vs Service)

| Aspect | Helm chart | Our kustomize tree |
|---|---|---|
| `webhooks[*].clientConfig` form | `url: https://metal-operator-webhook-service:443<path>` | `service: { name: webhook-service, namespace: system, path: <path> }` + ExternalName Service in `system` namespace pointing at `metal-operator-webhook-service` |
| Workerless API server resolves via | URL DNS (workerless API server pod's `/etc/resolv.conf`) | Service object (workerless API server queries its own etcd, then resolves `externalName` via the same `/etc/resolv.conf`) |

This is a **deliberate design choice** (not a bug) — see "Why no per-cluster customization for the externalName" above. Both forms reduce to the same DNS resolution. Service form is more idiomatic Kubernetes. Verified at design time; final cluster-specific verification belongs to cutover testing.

## Deferred design questions

### Fine-grained per-cluster override granularity

Today kube-secrets per-cluster overlays must replace whole `stringData` / `data` values when overriding placeholders embedded in multi-line YAML strings (e.g., the `remote-kubeconfig` ConfigMap's `APISERVER_URL_PLACEHOLDER`, the `metal-token-rotate-kubeconfig` Secret's `NAMESPACE_PLACEHOLDER`). The override granularity is "whole content" rather than "just the essential per-cluster value", which inflates per-cluster overlays and duplicates structure.

A cleaner pattern was explored during PR review (kustomize `replacements`, `configMapGenerator` / `secretGenerator` with `behavior: merge`, post-kustomize-build `envsubst` / Flux `postBuild.substituteFrom`). The mechanism choice depends on Concourse pipeline tooling availability and Flux migration trajectory, both unconfirmed. **Deferred** pending those clarifications. Tracked as follow-up in `tasks.md` §13.8. Affects multiple operators beyond metal-operator-remote — likely a cross-cutting capability candidate for a separate OpenSpec change.

## Per-environment component composition

The `remote/` kustomize root deliberately aggregates structural sources only — it has no environment tier baked in. Per-environment customization (currently the OIDC group name substitutions in `cc:oidc-ias-*` ClusterRoleBinding subjects, e.g., `CC_IAS_CONTROLPLANE_PROD_ADMIN` vs `CC_IAS_CONTROLPLANE_QA_ADMIN`) lives in kustomize Components under `custom/components/<env>/`. Selection happens at the kube-secrets per-cluster overlay level:

```yaml
# Example: kube-secrets per-cluster overlay (PROD cluster)
# values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/remote/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/sapcc/helm-charts//system/kustomize/metal-operator-remote/remote?ref=master
components:
  - https://github.com/sapcc/helm-charts//system/kustomize/metal-operator-remote/remote/custom/components/prod?ref=master
```

For a QA cluster the `components:` reference is the `qa/` Component. This separation means:

- **helm-charts owns** the kustomize structure and the per-environment Components (since these are a property of the metal-operator deployment, not of an individual cluster)
- **kube-secrets owns** the per-cluster decision of which environment tier the cluster belongs to (encoded as which Component to apply)

Build output of `kustomize build remote/` (without applying a Component) leaves OIDC bindings with `subjects[0].name: MUST_BE_SET_IN_OVERLAY` — this is intentional and serves as a tripwire if the per-cluster overlay forgets to apply an environment Component. It is governed by the `Per-environment component composition delegated to kube-secrets per-cluster overlays` requirement in `kustomize-resource-splitting`.

## SAP-CC deployment-wide defaults absorbed into the kustomize base

The kustomize base at `host/base/` and the webhook-injector Component carry SAP-CC deployment defaults that are uniform across the fleet, so per-cluster overlays only need to substitute genuinely cluster-specific values via `*_PLACEHOLDER` substitution. Empirical verification was done by inspecting all 6 currently-deployed clusters' values in `cc/kube-secrets`, plus a live cert decode from `m-eu-de-1`'s production VWC `caBundle` on 2026-06-01.

### Manager args (verified across 6 clusters)

7 of 8 controller-manager `args` are byte-identical across `a-qa-de-200`, `rt-eu-de-1`, `rt-eu-de-2`, `rt-eu-de-3`, `rt-na-us-2`, `rt-qa-de-1`:

```
--mac-prefixes-file=/etc/macdb/macdb.yaml
--probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:v0.5.0
--probe-os-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/gardenlinux/gardenlinux:1770.0
--manager-namespace=metal-servers
--insecure=false
--enforce-first-boot
--enforce-power-off
```

The 8th arg, `--registry-url`, varies per cluster: `https://metal-operator-remote.<clusterType>.<region>.<tld>` where `<clusterType>` is `runtime` for runtime clusters and `garden2` for `a-qa-de-200`. Base ships `--registry-url=REGISTRY_URL_PLACEHOLDER` for kube-secrets per-cluster substitution.

### macdb Secret (verified across 6 clusters)

The macdb structure is identical across all 6 clusters: 4 macPrefixes — Dell `c4cbe1b1`, Dell `d08e79`, Lenovo `0894ef`, HPE `5ced8c` — all Redfish protocol, port 443, type `bmc`. Vault references use `vault+kvv2:///secrets/<region>/ironic/ipmi-user/ironic/<username|password>`. Only the `<region>` token varies per cluster. Base ships the structure with `REGION_PLACEHOLDER` for the region token.

### Sidecar args (matches helm chart hardcoded values + PR #10 v2 patch mode)

Production sidecar args (read live from `rt-eu-de-1`'s shoot deployment):

```
--webhook-config-name=metal-operator-remote-webhook-config       (ConfigMap mode flag — Scope 3 drops this)
--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
--leader-election-id=metal-operator-remote-webhook-injector-leader
--cert-secret-name=metal-operator-remote-cert-secret-name
```

In Scope 3 with webhook-injector PR #10 v2's patch mode (label-based, no URL rewriting), sidecar args become:

```
--webhook-label=webhook-injector.cloud.sap/managed=true                 (NEW — replaces --webhook-config-name)
--cert-sans=metal-operator-webhook-service,                              (NEW — required in patch mode; covers
            webhook-service.system.svc,                                    production cert SAN + Scope 3 SNI)
            webhook-service.system.svc.cluster.local
--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
--leader-election-id=metal-operator-remote-webhook-injector-leader
--cert-secret-name=metal-operator-remote-cert-secret-name
```

The workerless `ValidatingWebhookConfiguration` is labeled `webhook-injector.cloud.sap/managed: "true"` via a kustomize patch on the upstream-shipped resource (name unchanged: `validating-webhook-configuration`). The sidecar's `--webhook-label` selector finds it by label.

### Cert SANs evidence

Decoded the production cert's caBundle from `m-eu-de-1`'s `metal-operator-validating-webhook-configuration` VWC on 2026-06-01 — single SAN: `DNS:metal-operator-webhook-service` (auto-derived by the binary from URL-form clientConfigs per `pkg/certificates/generator.go` in webhook-injector main branch). Scope 3 ships Service-form clientConfigs (`webhook-service.system.svc`) so the SNI changes — but the production SAN is preserved in our `--cert-sans` list to maintain compatibility during cutover and for any direct URL-form callers.
