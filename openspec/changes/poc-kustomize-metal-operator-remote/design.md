## Overview

POC for replacing the `metal-operator-remote` Helm chart entirely with pure kustomize overlays, using the upstream `ironcore-dev/metal-operator` repo's `config/` directory as the kustomize base for upstream-derived resources, and local resource files for custom host-side infrastructure.

**Goal**: Produce a complete kustomize-based deployment that replaces `system/metal-operator-remote/` (the Helm chart), covering both host (seed) and remote (virtual cluster) resources, compatible with Flux's kustomize-controller.

### Deployment Model

The remote cluster is a **workerless virtual cluster** — it has an API server but no nodes. The control plane (metal-operator) runs in the **host/seed cluster** and watches resources in the remote virtual cluster's API server.

```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│        Host / Seed Cluster       │    │    Remote (Virtual Cluster)      │
│                                  │    │    (API server only, no nodes)   │
│  ┌────────────────────────┐     │    │                                  │
│  │ metal-operator Pod      │     │    │  CRDs (metal.ironcore.dev/*)     │
│  │  - controller-manager   │────────▶│  RBAC (ClusterRoles, Bindings)   │
│  │  - webhook-injector     │     │    │  Webhook Configurations          │
│  └────────────────────────┘     │    │    (URL-based → calls back       │
│                                  │    │     to seed webhook service)     │
│  Services, Ingress, Secrets,     │    │                                  │
│  NetworkPolicy, ConfigMaps       │    └─────────────────────────────────┘
│                                  │              ▲
│  ManagedResource objects ────────────────────────┘
│  (GRM pushes resources to        │    (GRM applies CRDs/RBAC/webhooks
│   remote API server)             │     into remote API server)
└─────────────────────────────────┘
```

Key implications:
- The controller runs in the **seed** but reconciles resources in the **remote API server**
- CRDs must be registered in the remote API server so its clients can create metal-operator resources
- RBAC must exist in the remote API server to authorize access (all cluster-scoped since the virtual cluster has no namespace management)
- Webhooks are configured in the remote API server with **URL-based clientConfig** pointing back to the seed's webhook service (since the virtual cluster has no pods to route to)
- ManagedResources are the mechanism to push resources from seed → remote API server

## Architecture

### Directory Structure

```
system/kustomize/metal-operator-remote/
├── host/
│   ├── base/                                    # Environment-independent host resources
│   │   ├── kustomization.yaml                   # upstream config/manager + components + local resources
│   │   ├── manager-remote-patch.yaml            # patches upstream Deployment for remote operation
│   │   ├── manager-webhook-patch.yaml           # patches upstream Deployment for webhook serving
│   │   ├── webhook-service.yaml                 # Service: 443→9443 for webhook
│   │   ├── metal-registry-service.yaml          # Service: metal-registry (port 10000)
│   │   ├── ingress.yaml                         # Ingress: metal-registry (placeholder domain)
│   │   ├── networkpolicy.yaml                   # NetworkPolicy: ingress to registry
│   │   ├── webhook-injector-rbac.yaml           # SA + Role + RoleBinding for webhook-injector
│   │   ├── webhook-config.yaml                  # ConfigMap: wraps webhooks.yaml content
│   │   ├── remote-kubeconfig-configmap.yaml     # ConfigMap: kubeconfig for remote cluster
│   │   ├── remote-serviceaccount-secret.yaml    # Secret: token-requestor for remote SA
│   │   ├── macdb-secret.yaml                    # Secret: MAC database
│   │   └── rotate-kubeconfig-secret.yaml        # Secret: token rotation kubeconfig
│   └── overlays/
│       └── <cluster-name>/                      # Per-environment values
│           ├── kustomization.yaml               # patches base with env-specific values
│           └── patches/
│               ├── ingress-domain.yaml          # region, clusterType, tld
│               ├── remote-apiserver.yaml         # KUBERNETES_SERVICE_HOST
│               ├── macdb.yaml                   # macdb content
│               ├── remote-ca.yaml               # remote.ca certificate
│               └── images.yaml                  # image tags
├── remote/                                      # REMOTE virtual cluster resources (via ManagedResource)
│   ├── upstream/                                # Derived from upstream config/ — GENERATED by make regen
│   │   ├── crds-and-rbac/
│   │   │   ├── kustomization.yaml              # refs config/crd + config/rbac @ pinned tag
│   │   │   └── managedresources.yaml           # pre-rendered ManagedResource+Secret wrappers
│   │   └── webhooks/
│   │       ├── source/
│   │       │   └── kustomization.yaml          # refs config/webhook @ pinned tag (input for regen)
│   │       ├── kustomization.yaml              # resources: [manifests-url-based.yaml]
│   │       ├── manifests-url-based.yaml        # pre-rendered URL-based webhook configs
│   │       └── managedresources.yaml           # pre-rendered ManagedResource+Secret wrappers
│   └── custom/                                  # Manually maintained, NOT from upstream
│       ├── base/
│       │   ├── kustomization.yaml              # local custom resources
│       │   ├── namespace.yaml                  # static: Namespace metal-servers
│       │   └── rbac.yaml                       # parameterized: IAS bindings, token-rotate, webhook-injector RBAC
│       └── overlays/
│           └── <cluster-name>/
│               ├── kustomization.yaml
│               └── rbac-patch.yaml             # IAS group names (qa vs prod), adminLDAPUsers
├── components/
│   └── webhook-injector/
│       ├── kustomization.yaml                  # kind: Component
│       └── sidecar.yaml                        # initContainer strategic merge patch
└── Makefile                                     # regen remote resources only
```

### Two-tier model: Build time vs. Deploy time

**Build time** (on upstream version bumps — `make regen`):
- Regenerates `remote/` pre-rendered files only
- Remote resources are static, environment-independent (same CRDs/RBAC/webhooks for all clusters)
- Output committed to git
- Future possibility: a GitHub Action that automatically runs `make regen` when upstream refs are bumped in a PR, commits the regenerated files, and validates equivalence — eliminating manual build steps entirely

**Deploy time** (Flux `Kustomization` per cluster):
- Host resources: Flux points at `host/overlays/<cluster-name>/` → runs `kustomize build` → deploys to seed
- Remote upstream resources: Flux points at `remote/upstream/` pre-rendered ManagedResource files → deploys to seed (GRM applies to remote API server). These are static/env-independent.
- Remote custom resources: Flux points at `remote/custom/overlays/<cluster-name>/` → runs `kustomize build` → deploys to seed (GRM applies to remote API server). These are parameterized per-env.

### Resource Flow

```
┌─────────────────────────────────────────────────┐
│ Upstream: github.com/ironcore-dev/metal-operator │
│   config/crd/    config/rbac/                    │
│   config/manager/    config/webhook/             │
└────────────┬────────────────────┬───────────────┘
             │                    │
     ┌───────┴───────┐   ┌───────┴────────────┐
     │  host/base/   │   │ remote/upstream/    │
     │ (deploy-time  │   │ (build-time         │
     │  kustomize)   │   │  pre-render)        │
     └───────┬───────┘   └───────┬─────────────┘
             │                    │ make regen
     ┌───────┴───────┐   ┌───────┴────────────┐
     │ host/overlays │   │ managedresources   │
     │ /<cluster>/   │   │ .yaml (committed)  │
     │ (per-env      │   │                    │
     │  values)      │   │                    │
     └───────┬───────┘   └───────┬────────────┘
             │                    │
             ▼                    ▼
     ┌───────────────┐   ┌───────────────────┐
     │ Flux builds   │   │ Flux deploys      │
     │ overlay →     │   │ static files      │
     │ seed cluster  │   │ → seed (GRM →     │
     │               │   │   remote API)     │
     └───────────────┘   └───────────────────┘

 ┌───────────────────────────────────────────┐
 │ remote/custom/ (manually maintained)      │
 │   namespace.yaml (static)                 │
 │   rbac.yaml (parameterized per-env)       │
 └───────────────────┬──────────────────────┘
                     │
         ┌───────────┴───────────┐
         │ remote/custom/overlays│
         │ /<cluster>/           │
         │ (per-env patches)     │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Flux builds overlay   │
         │ → ManagedResources    │
         │ → seed (GRM →         │
         │   remote API)         │
         └───────────────────────┘
```
┌─────────────────────────────────────────────────┐
│ Upstream: github.com/ironcore-dev/metal-operator │
│   config/crd/    config/rbac/                    │
│   config/manager/    config/webhook/             │
└────────────┬────────────────────┬───────────────┘
             │                    │
     ┌───────┴───────┐   ┌───────┴───────┐
     │  host/base/   │   │   remote/     │
     │ (deploy-time  │   │ (build-time   │
     │  kustomize)   │   │  pre-render)  │
     └───────┬───────┘   └───────┬───────┘
             │                    │ make regen
     ┌───────┴───────┐   ┌───────┴───────┐
     │ host/overlays │   │ managed       │
     │ /<cluster>/   │   │ resources.yaml│
     │ (per-env      │   │ (committed)   │
     │  values)      │   │               │
     └───────┬───────┘   └───────┬───────┘
             │                    │
             ▼                    ▼
     ┌───────────────┐   ┌───────────────┐
     │ Flux builds   │   │ Flux deploys  │
     │ overlay →     │   │ static files  │
     │ seed cluster  │   │ → seed (GRM → │
     │               │   │   remote API) │
     └───────────────┘   └───────────────┘
```

## Components

### host/base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Upstream Deployment base
  - https://github.com/ironcore-dev/metal-operator//config/manager?ref=v0.4.0
  # Local host resources
  - webhook-service.yaml
  - metal-registry-service.yaml
  - ingress.yaml
  - networkpolicy.yaml
  - webhook-injector-rbac.yaml
  - webhook-config.yaml
  - remote-kubeconfig-configmap.yaml
  - remote-serviceaccount-secret.yaml
  - macdb-secret.yaml
  - rotate-kubeconfig-secret.yaml
components:
  - ../../components/webhook-injector
patches:
  # Remove the Namespace resource from upstream config/manager
  - target:
      kind: Namespace
    patch: |
      $patch: delete
      apiVersion: v1
      kind: Namespace
      metadata:
        name: system
  - path: manager-remote-patch.yaml
  - path: manager-webhook-patch.yaml
images:
  - name: controller
    newName: ghcr.io/ironcore-dev/metal-operator-controller-manager
    newTag: sha-4854c23
```

### host/base/manager-remote-patch.yaml

Strategic merge patch for remote-cluster operation:
- Sets `strategy.type: Recreate`
- Adds env vars: `KUBERNETES_SERVICE_HOST`, `KUBERNETES_CLUSTER_DOMAIN`, `KUBECONFIG`
- Mounts `remote-serviceaccount` secret and `remote-kubeconfig` configmap
- Adds Gardener network policy pod labels
- Sets `serviceAccountName: metal-operator-webhook-injector`
- Sets `securityContext.runAsUser/runAsGroup: 65532`
- Adds operator-specific args (`--mac-prefixes-file`, `--probe-image`, etc.)

### host/base/manager-webhook-patch.yaml

Strategic merge patch for webhook support:
- Adds webhook-server port (9443)
- Adds `webhook-certs` emptyDir volume + mount
- Adds `macdb` secret volume + mount

### host/overlays/<cluster-name>/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
patches:
  - path: patches/ingress-domain.yaml
  - path: patches/remote-apiserver.yaml
  - path: patches/macdb.yaml
  - path: patches/remote-ca.yaml
images:
  - name: ghcr.io/ironcore-dev/metal-operator-controller-manager
    newTag: <env-specific-tag>
  - name: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector
    newTag: <env-specific-tag>
```

Per-environment patches override:
- Ingress domain (region, clusterType, tld)
- Remote apiserver URL (`KUBERNETES_SERVICE_HOST`)
- macdb Secret content
- Remote CA certificate
- Image tags

### components/webhook-injector/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches:
  - path: sidecar.yaml
images:
  - name: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector
    newTag: latest
```

### components/webhook-injector/sidecar.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: controller-manager
spec:
  template:
    spec:
      initContainers:
        - name: webhook-injector
          restartPolicy: Always
          image: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest
          args:
            - --webhook-config-name=webhook-config
            - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
          ports:
            - name: metrics
              containerPort: 8082
            - name: health
              containerPort: 8083
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - "ALL"
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8083
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8083
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          volumeMounts:
            - name: webhook-certs
              mountPath: /tmp/webhook-certs
            - name: remote-serviceaccount
              mountPath: /var/run/secrets/kubernetes.io/remote-serviceaccount
              readOnly: true
            - name: remote-kubeconfig
              mountPath: /var/run/remote-kubeconfig
              readOnly: true
```

### remote/crds-and-rbac/kustomization.yaml

The upstream `config/rbac/role.yaml` already uses `ClusterRole` and `role_binding.yaml` uses
`ClusterRoleBinding`. However, `leader_election_role.yaml` uses namespace-scoped `Role` and
`leader_election_role_binding.yaml` uses `RoleBinding`.

The current Makefile does a blanket `sed 's/kind: Role/kind: ClusterRole/g'` which also
converts `RoleBinding` → `ClusterRoleBinding` (substring match). It does NOT remove any
RBAC resources — everything goes to the remote cluster. The only resources excluded are
Service, ValidatingWebhookConfiguration, and MutatingWebhookConfiguration.

Strategy: Include all of `config/rbac/`, convert remaining Role/RoleBinding to
ClusterRole/ClusterRoleBinding via JSON patch. Remove nothing.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kube-system
resources:
  - https://github.com/ironcore-dev/metal-operator//config/crd?ref=v0.4.0
  - https://github.com/ironcore-dev/metal-operator//config/rbac?ref=v0.4.0
patches:
  # Convert namespace-scoped Role → ClusterRole (all remote resources must be cluster-scoped)
  - target:
      kind: Role
    patch: |
      - op: replace
        path: /kind
        value: ClusterRole
  # Convert namespace-scoped RoleBinding → ClusterRoleBinding
  - target:
      kind: RoleBinding
    patch: |
      - op: replace
        path: /kind
        value: ClusterRoleBinding
```

### remote/webhooks/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - manifests-url-based.yaml
```

## Flux Compatibility (out of scope, but no blockers)

The design avoids introducing Flux blockers:
- No custom KRM function plugins (Flux doesn't support them)
- Host overlays produce valid `kustomize build` output — Flux Kustomization can point directly at `host/overlays/<cluster>/`
- Remote pre-rendered files are plain YAML — Flux deploys them as static resources
- Remote git resources in `kustomization.yaml` are supported by Flux's kustomize-controller

When Flux integration is tackled later:
- One Flux `Kustomization` per cluster for host → `host/overlays/<cluster-name>/`
- One shared Flux `Kustomization` for remote → `remote/` pre-rendered ManagedResource files

## Upgrade Process

1. Update `?ref=v0.4.0` → `?ref=v0.5.0` in all kustomization files (host/base + remote)
2. Run `make regen` (rebuilds remote pre-rendered files only)
3. Review diffs in pre-rendered files
4. Commit and push — Flux deploys

### Makefile targets

```makefile
.PHONY: regen regen-remote-crds regen-remote-webhooks

KUSTOMIZE_DIR := system/kustomize/metal-operator-remote

regen: regen-remote-crds regen-remote-webhooks

regen-remote-crds:
	@kustomize build $(KUSTOMIZE_DIR)/remote/upstream/crds-and-rbac | \
		scripts/wrap-managedresources.sh > $(KUSTOMIZE_DIR)/remote/upstream/crds-and-rbac/managedresources.yaml

regen-remote-webhooks:
	@kustomize build $(KUSTOMIZE_DIR)/remote/upstream/webhooks/source | \
		yq '(.webhooks[].clientConfig | select(.service)) |= \
		{"url": "https://metal-operator-webhook-service:443" + .service.path}' | \
		yq 'del(.webhooks[].clientConfig.service)' \
		> $(KUSTOMIZE_DIR)/remote/upstream/webhooks/manifests-url-based.yaml
	@kustomize build $(KUSTOMIZE_DIR)/remote/upstream/webhooks | \
		scripts/wrap-managedresources.sh > $(KUSTOMIZE_DIR)/remote/upstream/webhooks/managedresources.yaml
```

Note: Host resources and remote custom resources are NOT pre-rendered — Flux builds their overlays at deploy time.
The `scripts/wrap-managedresources.sh` script takes multi-document YAML on stdin and produces ManagedResource+Secret pairs (matching the logic in the current `templates/managedresource.yaml`).

### Remote custom resources

The `remote/custom/` directory contains manually maintained resources that are NOT derived from upstream:

**`namespace.yaml`** — Static
- `Namespace: metal-servers`

**`rbac.yaml`** — Parameterized per environment
- OIDC IAS admin/viewer/editor bindings (group names differ for qa vs prod regions)
- `metal-token-rotate` ServiceAccount + ClusterRole + ClusterRoleBinding + Role + RoleBinding
- `metal-api-viewer` ClusterRole (viewer for metal/boot/ipam resources)
- `metal-operator-webhook-injector` ClusterRole + ClusterRoleBinding (for injector in remote cluster)
- LDAP cluster-admin bindings (list of admin users varies per environment)

These are wrapped into ManagedResources at deploy time via `kustomize build remote/custom/overlays/<cluster>/` which renders the parameterized resources and pipes through the ManagedResource wrapping (either as a kustomize generator or a post-build step in Flux).

## Equivalence Verification

The POC should include a comparison script:

```bash
#!/bin/bash
# Compare kustomize output vs current Helm chart rendered output
# For a specific environment overlay:
diff <(kustomize build host/overlays/test/ | yq 'sort_keys(..)') \
     <(helm template metal-operator-remote ../metal-operator-remote/ -f test-values.yaml | yq 'sort_keys(..)')
```

## Constraints

- Requires kustomize v5+ for `patches[].target.kind` matching (Role→ClusterRole for leader election)
- Flux kustomize-controller must support remote git resources in `kustomization.yaml`
- No custom KRM function plugins (Flux doesn't support them)
- webhook-injector is a black box — cannot modify its implementation
- Upstream `config/` directory structure must remain stable across releases
- All RBAC must be cluster-scoped in the remote virtual cluster (no namespace management in the workerless virtual cluster)
- Host resources require per-environment parameterization via overlays

## Reproducibility Across Operators

The pattern should apply to:
- `boot-operator-remote` — same structure, different webhook paths
- `argora-operator-remote` — same structure, no webhooks
- `ipam-capi-remote` — already uses kustomize (can adopt this folder convention)

Shared components (`components/webhook-injector/`) reduce per-operator duplication.
