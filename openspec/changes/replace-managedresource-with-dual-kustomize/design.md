# Design: replace-managedresource-with-dual-kustomize

> Pre-filled from the brainstorming session. The OpenSpec `design` artifact (when promoted via `/opsx-continue`) may extend or refine this document; the brainstorm-stage content below is the architectural foundation.

> **⚠️ ARCHITECTURAL PIVOT (post-PR-push, see "Why admission-webhook bootstrap, not ExternalName" section below).** This document was originally written assuming ExternalName-based routing on the workerless cluster + caBundle-only patch mode in the sidecar. Code-level inspection of [SAP-cloud-infrastructure/webhook-injector#10](https://github.com/SAP-cloud-infrastructure/webhook-injector/pull/10) v2 (HEAD `06b512f`) revealed `--external-host` is mandatory in patch mode (forces a Service→URL rewrite), and PR-10-v2 ships an admission-webhook bootstrap mechanism that solves a GitOps-reconciliation idempotency problem the ExternalName approach hadn't grappled with. ExternalName was independently a latent risk on Gardener ([k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659)). The final architecture replaces ExternalName routing entirely with PR-10-v2 patch mode + admission-webhook bootstrap. **Read the "Why admission-webhook bootstrap, not ExternalName" section first**, then the rest of this document for context. Inline references to ExternalName / `system` namespace / `webhook-service-stub.yaml` / `upstream-no-svc/` throughout this doc remain as historical record of the pre-pivot exploration; the spec deltas in `specs/` are authoritative for the final state.

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
| `system` | **WORKERLESS** | NEW: `remote/upstream/metal-operator-webhooks/system-namespace.yaml` (introduced by this change) | Holds the `webhook-service` ExternalName Service. Matches upstream's `clientConfig.service.namespace=system` placeholder — by deploying upstream's webhook config verbatim and creating this namespace + ExternalName Service, no URL rewrite is required. |
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
│   ├── kustomization.yaml                      # aggregates STRUCTURAL SOURCES ONLY: upstream/metal-operator-crds-and-rbac + upstream/metal-operator-webhooks + custom/base. Does NOT bind to a specific environment tier — per-environment components (prod/qa) are applied by kube-secrets per-cluster overlays based on cluster tier.
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
- `system/kustomize/metal-operator-remote/remote/upstream/metal-operator-crds-and-rbac/managedresources.yaml`
- `system/kustomize/metal-operator-remote/remote/upstream/metal-operator-webhooks/managedresources.yaml`
- `system/kustomize/metal-operator-remote/remote/upstream/metal-operator-webhooks/manifests-url-based.yaml` (obsolete — kustomize live-fetches upstream `config/webhook/`)
- `system/kustomize/metal-operator-remote/host/base/webhook-config.yaml` (obsolete — sidecar no longer reads webhook content from a local ConfigMap)
- `system/Makefile` targets `regen-metal-operator-remote*` (and any helper variables)
- The `patches:` block in `remote/upstream/metal-operator-crds-and-rbac/kustomization.yaml` that converts upstream `Role` → `ClusterRole` and `RoleBinding` → `ClusterRoleBinding`

## Why admission-webhook bootstrap, not ExternalName

**(Final architecture — supersedes the "Webhook delivery via ExternalName + Git URL ref" section that follows.)**

### Two findings that forced the pivot

1. **`--external-host` is mandatory in PR-10-v2 patch mode.** Code inspection of `SAP-cloud-infrastructure/webhook-injector` branch `optional-webhook-config-and-crd-patching` at HEAD `06b512f`:

   ```go
   // cmd/webhook-injector/main.go ~L130-L142
   if patchModeActive && externalHost == "" {
       setupLog.Error(nil, "--external-host is required in patch mode")
       os.Exit(1)
   }
   if patchModeActive && (externalPort < 1 || externalPort > 65535) {
       setupLog.Error(nil, "--external-port is required in patch mode and must be in [1, 65535]", "value", externalPort)
       os.Exit(1)
   }
   ```

   The previous design ran patch mode without `--external-host` (caBundle-only refresh). The new binary refuses to start in that configuration. Either we provide an `--external-host`/`--external-port` (which triggers Service→URL rewrite on every reconcile) or we use ConfigMap mode (which we don't want).

2. **Service→URL rewrite without admission interception breaks GitOps reconciliation.** The K8s admissionregistration validation explicitly rejects resources where both `clientConfig.Service` and `clientConfig.URL` are set:

   ```go
   // pkg/apis/admissionregistration/validation/validation.go
   case (cc.URL == nil) == (cc.Service == nil):
       allErrors = append(allErrors, field.Required(fldPath.Child("clientConfig"),
           "exactly one of url or service is required"))
   ```

   Without admission interception, every Concourse re-apply re-introduces the Service field via `kubectl apply`'s 3-way merge (last-applied-annotation: Service form; new manifest: Service form, unchanged; live state: URL form set by the periodic sidecar reconciler). Merge result has both fields set → validation rejects the apply. Server-Side Apply with field-manager separation doesn't fix this — validation runs after merge regardless of ownership.

### How admission-webhook bootstrap solves both

PR-10-v2 ships an admission-webhook bootstrap mechanism (new in this revision of the PR). When `--admission-webhook-name` is set in patch mode (default `webhook-injector-mutator`), the controller bootstraps a `MutatingWebhookConfiguration` on the **target cluster** (= workerless cluster in our topology) whose `objectSelector` matches `--webhook-label`. This MWC has three webhook entries pointing at `/mutate-mwc`, `/mutate-vwc`, `/mutate-crd` paths served by the controller's in-pod admission server. CREATE/UPDATE on labeled MWC/VWC/CRD resources is mutated synchronously — `caBundle` is stamped and `clientConfig.Service` is rewritten to `clientConfig.URL` form **at admission time**, so the workerless apiserver only ever **stores** URL form. Re-applies become idempotent:

```
Concourse re-apply → kubectl apply -k remote/        (Service form)
                  ↓
Workerless apiserver → mutating-admission phase     (mutator rewrites Service → URL)
                  ↓
                  → validating-admission phase      (only URL set → passes)
                  ↓
                  → etcd                             (URL form stored)
```

The periodic reconciler stays as a drift safety net; the admission webhook is the primary mechanism. Webhook entries use `failurePolicy: Ignore`, `sideEffects: None`, `timeoutSeconds: 5` (per PR description) — so the workerless cluster's writes to labeled webhook configs continue to work even when webhook-injector itself is down (degraded-mode tolerance).

### Why not ExternalName

ExternalName routing was independently a latent risk on Gardener: k3s/Gardener default `--enable-aggregator-routing=true` rejects ExternalName for webhook clientConfig per [k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659). The aggregator-routing feature gate makes the apiserver bypass cluster DNS for webhook Service resolution — it queries the Service object directly and routes to Pod IPs from the Service's selector. ExternalName has no Pod IPs (the externalName field is a CNAME for DNS, not a selector for endpoints), so the apiserver's webhook router can't dispatch the call. The pivot to admission-webhook bootstrap eliminates the dependency on ExternalName entirely.

### Final architecture (steady state)

```
┌─────────────────────────────── HOST CLUSTER ───────────────────────────────┐
│                                                                            │
│  controller-manager Pod                                                    │
│  ├── manager container (port 9443, webhook server)                         │
│  └── webhook-injector sidecar initContainer                                │
│      ├── --webhook-label=webhook-injector.cloud.sap/managed=true           │
│      ├── --external-host=metal-operator-webhook-service                    │
│      ├── --external-port=443                                               │
│      ├── --admission-webhook-name=metal-operator-webhook-injector-mutator  │
│      ├── --admission-external-port=9444                                    │
│      └── in-pod admission server (port 9444)                               │
│                                                                            │
│  Service metal-operator-webhook-service                                    │
│    ports:                                                                  │
│      - name: webhook,    port: 443  → targetPort 9443  (manager webhook)   │
│      - name: admission,  port: 9444 → targetPort 9444  (sidecar admission) │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
                                ▲
                                │ DNS via host-cluster CoreDNS
                                │ (workerless apiserver Pod's /etc/resolv.conf)
                                │
┌─────────────────────── WORKERLESS CLUSTER ─────────────────────────────────┐
│                                                                            │
│  ValidatingWebhookConfiguration validating-webhook-configuration           │
│    metadata.labels.webhook-injector.cloud.sap/managed: "true"              │
│    webhooks[*].clientConfig:                                               │
│      build-time:  service: { name: webhook-service, namespace: system }    │
│      stored:      url: https://metal-operator-webhook-service:443/<path>   │
│                   caBundle: <base64 cert from sidecar>                     │
│                                                                            │
│  MutatingWebhookConfiguration metal-operator-webhook-injector-mutator      │
│    (bootstrapped by sidecar on first reconcile; not in git)                │
│    objectSelector: webhook-injector.cloud.sap/managed=true                 │
│    webhooks:                                                               │
│      - /mutate-mwc                                                         │
│      - /mutate-vwc  ← intercepts the VWC above on every CREATE/UPDATE      │
│      - /mutate-crd                                                         │
│    All entries: clientConfig.url =                                         │
│      https://metal-operator-webhook-service:9444/mutate-{mwc,vwc,crd}      │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

No ExternalName Service. No `system` Namespace (the upstream `service.yaml` is not applied to the workerless cluster — we consume only `manifests.yaml`). The VWC's `clientConfig.service.namespace=system` field reference is harmless: K8s does not validate Service existence at VWC apply time, and admission rewrite replaces it with URL form before any callback fires.

### Bootstrap-window risk and mitigation

On a **fresh install** of a new workerless cluster, the order between `host/` apply (brings up sidecar → bootstraps the admission webhook on the workerless cluster) and `remote/` apply (delivers the labeled VWC) matters. If `remote/` lands first, the VWC enters the workerless apiserver in Service form pointing at a non-existent Service, and upstream's `failurePolicy: Fail` × 7 webhook entries (BiosSettings, BiosVersion, BmcSecret, BmcSettings, BmcVersion, Endpoint, Server) blocks all metal3 CRD writes until the periodic reconciler recovers (up to one `--sync-period`). Mitigation lives in the Concourse pipeline (`cc/kube-secrets`): a gate task between the two apply jobs that polls for the bootstrapped MWC:

```
kubectl --kubeconfig=$REMOTE_KUBECONFIG \
  wait --for=jsonpath='{.metadata.name}'=metal-operator-webhook-injector-mutator \
  mutatingwebhookconfiguration/metal-operator-webhook-injector-mutator \
  --timeout=5m
```

The gate is idempotent (instant return on subsequent runs once the MWC exists). See `tasks.md` Section 16.14 and `plan.md` Task 14.6 for full coordination notes.

### RBAC widening (cross-repo)

The remote-kubeconfig identity (delivered via `cc/kube-secrets`) needs `mutatingwebhookconfigurations` `create,get,list,watch,update,patch` on the workerless cluster (to bootstrap `metal-operator-webhook-injector-mutator`), in addition to the existing `validatingwebhookconfigurations` verbs. The recommended pattern is to consume upstream's canonical target-cluster RBAC verbatim:

```yaml
# cc/kube-secrets per-cluster overlay
resources:
  - https://github.com/SAP-cloud-infrastructure/webhook-injector//config/rbac.yaml?ref=<tag>
patches:
  # Override only the binding subjects to point at the remote-kubeconfig user identity
  - target: { kind: ClusterRoleBinding, name: webhook-injector-target }
    patch: |
      - op: replace
        path: /subjects
        value:
          - kind: User
            name: <remote-kubeconfig user>
            apiGroup: rbac.authorization.k8s.io
  # Drop upstream's host-side SA/Role/RoleBinding (irrelevant on workerless)
  - target: { kind: ServiceAccount, name: webhook-injector }
    patch: '$patch: delete'
  - target: { kind: Role, name: webhook-injector }
    patch: '$patch: delete'
  - target: { kind: RoleBinding, name: webhook-injector }
    patch: '$patch: delete'
```

This avoids a hand-rolled verb list and auto-inherits any future RBAC widening from upstream (e.g., new resource types).

---

## Webhook delivery via ExternalName + Git URL ref

> **⚠️ HISTORICAL — superseded by "Why admission-webhook bootstrap, not ExternalName" above.** The ExternalName approach described in this section was the original architecture during brainstorming, but was discarded during PR review (see pivot callout at top of file). The content below remains as record of the design exploration.

```
┌──────────────────── helm-charts ─────────────────────────────────────┐
│                                                                       │
│ remote/upstream/metal-operator-webhooks/upstream-no-svc/kustomization.yaml          │
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
│ remote/upstream/metal-operator-webhooks/kustomization.yaml (outer)                   │
│   resources:                                                          │
│     - upstream-no-svc/                                                │
│       # ↑ references the inner layer's output: webhook config only.   │
│     - system-namespace.yaml                                           │
│     - webhook-service-stub.yaml                                       │
│       # ↑ OUR ExternalName Service. No identifier conflict with       │
│         upstream's Service because the inner layer already removed    │
│         it.                                                           │
│                                                                       │
│ remote/upstream/metal-operator-webhooks/system-namespace.yaml                       │
│   apiVersion: v1                                                      │
│   kind: Namespace                                                     │
│   metadata:                                                           │
│     name: system                                                      │
│                                                                       │
│ remote/upstream/metal-operator-webhooks/webhook-service-stub.yaml                   │
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

The webhook-injector sidecar populates `caBundle` at runtime. Subsequent `kubectl apply -k remote/` (or Flux reconciliation) preserves the sidecar's value via `kubectl apply`'s three-way merge — but ONLY if the applied manifest never includes `caBundle`. Upstream's `config/webhook/manifests.yaml` already omits `caBundle`, so the verbatim Git URL ref is safe. Any future patch added to `remote/upstream/metal-operator-webhooks/` MUST NOT introduce a `caBundle` field, even an empty string — that would clobber the sidecar's value on every apply, creating a webhook-failure window.

Verifiable by `kustomize build remote/upstream/metal-operator-webhooks/ | yq '.. | select(.caBundle? // "missing")'` returning empty (a verify-phase test).

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

## Helm-vs-kustomize equivalence gap analysis (post-PR review, 2026-06-05)

A diff between `helm template metal-operator-remote ./system/metal-operator-remote -f <a-qa-de-200/k3s-admin values>` and `kustomize build system/kustomize/metal-operator-remote/host/base/` (with the post-pivot architecture from Section 16) surfaced 7 gaps. Each is dispositioned per the OQ10 transitivity argument applied during webhook-injector RBAC absorption (Section 16): **fleet-uniform values belong in helm-charts; per-cluster values belong in kube-secrets**.

| # | Gap | Disposition |
|---|---|---|
| 1 | Kustomize renders **1** NetworkPolicy; helm renders **5**. 4 NPs missing in kustomize, all fleet-uniform (no per-cluster value substitution required, verified by reading `system/metal-operator-remote/templates/networkpolicy.yaml`). | **fix in this repo** (Section 17) |
| 2 | The 1 NP that exists in kustomize lacks `spec.policyTypes`. K8s defaults to `[Ingress]` when only Ingress rules are present (functionally equivalent), but explicit form matches helm's pattern + best practice. | **fix in this repo** (Section 17) |
| 3 | Pod selector label mismatch: kustomize `app.kubernetes.io/name: metal-operator` (upstream's bare name) vs helm `metal-operator-remote` (chart-fullname-prefixed). Internal consistency in the kustomize stack is preserved; mismatch only affects cutover transition. | **decision required** (this section) |
| 4 | Deployment name mismatch: kustomize `controller-manager` vs helm `metal-operator-controller-manager`. Same root cause as #3. | **decision required** (this section) |
| 5 | Manager image SHA divergence (helm pin in `values.yaml` vs cc/kube-secrets per-cluster overlay pin in the `images:` block). The kustomize base ships `:PLACEHOLDER` (literal) which the kube-secrets `images:` block substitutes per-cluster — this is the correct architectural division. The divergence observed is an operational artifact (which SHA to roll forward with), not a code gap. | **no code change** — operator decision, runbook material |
| 6 | `metal-operator-remote-webhook-config` ConfigMap eliminated in kustomize. | **already correct** (Section 5 — pivot artifact) |
| 7 | webhook-injector Role rule `configmaps: get,list,watch` dropped in kustomize. | **already correct** (Section 5 — pivot artifact) |

### Cutover decision for items 3 + 4 (label + Deployment rename)

**Cutover failure mode without mitigation.** After `kubectl apply -k host/` lands in a cluster currently running the helm chart, the kustomize Service `metal-operator-webhook-service` (selector: `app.kubernetes.io/name=metal-operator,control-plane=controller-manager`) finds zero endpoints — helm-deployed Pods carry `app.kubernetes.io/name=metal-operator-remote`. The Service VIP exists but routes nowhere. Webhook callbacks (workerless apiserver → host Service) fail with TCP connection refused. With `failurePolicy: Fail` × 7 metal3 webhook entries (Section 16 bootstrap-window discussion), all metal3 CRD writes block until the kustomize Deployment becomes Ready and pods labeled `metal-operator` exist. Item 4 (Deployment rename) compounds this: if the helm Deployment isn't deleted before kustomize Deployment is applied, **two** Deployments co-exist and fight over RBAC + leader election.

**Three mitigation options:**

- **(a) Bridge with `commonLabels`.** Add `commonLabels: { app.kubernetes.io/name: metal-operator-remote }` to `host/base/kustomization.yaml`. The kustomize tree projects the helm-naming everywhere (Deployment podLabels, Service selectors, NP podSelectors), so the kustomize Service immediately matches helm-deployed Pods during transition. Requires a future cleanup commit post-cutover to drop the override and adopt upstream's bare name. **Safer cutover, more long-term cruft.**
- **(b) Accept the rename + tested cutover runbook.** Keep the kustomize tree's bare name `metal-operator`. Document a tested cutover runbook in `cc/kube-secrets`: `kubectl scale deployment metal-operator-controller-manager --replicas=0` (helm-deployed) → `kubectl apply -k host/` (kustomize) → wait for kustomize Pods Ready (with new labels) → `kubectl apply -k remote/` → `helm uninstall metal-operator-remote`. Cleaner long-term naming, **requires a tested runbook + scheduled maintenance window**.
- **(c) Bridging selector with `matchExpressions`.** Service+NP selectors match both pod-label sets via `matchExpressions: [{key: app.kubernetes.io/name, operator: In, values: [metal-operator, metal-operator-remote]}]`. Most flexible during transition; most temporary kustomize cruft.

**Recommendation: (a)** as default unless the cutover runbook (b) is fully tested in non-production first. (a) is mechanical (5-line addition to one file), preserves the dual-kustomize migration's long-term naming intent (just deferred to a follow-up commit), and eliminates the orphan-endpoint failure mode entirely. Once production cutover completes on every cluster and the helm chart is fully retired, a separate small commit drops the `commonLabels` override and the kustomize tree adopts upstream's bare name.

The actual choice belongs in `tasks.md` 17.2 — implementer SHALL document the chosen option in this section once decided.

### Item 5 is not a code gap

The kustomize base correctly carries `:PLACEHOLDER` for the manager image; the cc/kube-secrets per-cluster overlay's `images:` block does the SHA pinning per cluster (already-merged Scope 2 architecture). The "divergence" between helm's `values.yaml` default SHA and the cc/kube-secrets pin is an operational artifact: at any given moment, different clusters may pin to different versions during a rollout. There is no code-side action required in either helm-charts or cc/kube-secrets — only an operator decision at cutover time about which SHA to roll forward with. This is captured in OQ5.

### A+B+C documentation pattern (cross-repo)

Consistent with the cc/kube-secrets verify.md pattern used during Scope 2:

- **(A)** This repo (helm-charts) owns the **fix** for items 1, 2, 3, 4 — captured in `tasks.md` Section 17.
- **(B)** cc/kube-secrets owns the **comparison evidence record** in its `verify.md` (PASS WITH WARNINGS), listing all 7 gaps and cross-linking to this section + Section 17.
- **(C)** Cross-link both: this section references the cc/kube-secrets verify.md pattern; cc/kube-secrets verify.md references this section as the authoritative gap inventory.



- **Bootstrap window**: between step 1 and step 2, the workerless cluster has CRDs and `ValidatingWebhookConfiguration` (with empty `caBundle`). Webhook callbacks fail TLS verification (failurePolicy=Fail blocks writes). The controller is the only writer; it isn't running yet, so the window is operationally benign. Once step 2 brings up the sidecar and it patches caBundle, admission validation works.
- **Drift recovery for webhook content**: the workerless `ValidatingWebhookConfiguration` is kustomize-managed. Manual edits to its `webhooks[*]` entries persist until the next `kubectl apply -k remote/` (Concourse trigger) or Flux Kustomization reconciliation. Flux's default reconciliation interval (typically 10 min) limits drift duration; Concourse-driven flows have longer drift windows tied to deploy cadence.
- **Drift recovery for caBundle**: the sidecar reconciles `caBundle` continuously. Manual edits to `caBundle` are repaired on the next sidecar reconciliation pass.
- **Cluster teardown**: when a cluster is decommissioned, `kubectl delete -k remote/` cleanly removes the workerless `ValidatingWebhookConfiguration` + `system` Namespace + ExternalName Service + CRDs + RBAC + custom RBAC + the `metal-servers` user-facing namespace. In typical operations the workerless cluster is destroyed wholesale, making this moot. The explicit teardown command is a useful runbook addition in the kube-secrets coordinated change.
- **Webhook content updates from upstream**: editing the upstream metal-operator pinned ref in `remote/upstream/metal-operator-webhooks/kustomization.yaml` (e.g., `?ref=v0.4.0` → `?ref=v0.5.0`) updates the workerless `ValidatingWebhookConfiguration` on the next `kubectl apply -k remote/`. No manual regeneration step. The sidecar reconciles `caBundle` against the new webhook configs automatically.
- **`caBundle` invariant** (already noted in design above): the kustomize tree MUST NOT emit `caBundle` in any webhook entry. Verify-phase test: `kustomize build remote/upstream/metal-operator-webhooks/ | yq '.. | select(.caBundle? // "missing")'` → empty.

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
