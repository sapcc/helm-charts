# metal-operator-remote (Kustomize)

Kustomize-based deployment of the metal-operator in a split host/remote cluster setup. Replaces the previous Helm chart at `system/metal-operator-remote/`.

## Prerequisites

- `kustomize` v5+ (for `patches[].target.kind` matching)
- `yq` v4+ (for webhook URL regeneration)
- `kubectl` (for verification)

## Directory Layout

```
.
├── host/
│   ├── base/              # Shared resources for all environments
│   └── overlays/          # Per-cluster host-specific values
│       └── rt-eu-de-1/
├── remote/
│   ├── upstream/          # Generated from upstream ironcore-dev/metal-operator
│   │   ├── crds-and-rbac/ # CRDs + RBAC for remote API server
│   │   └── webhooks/      # Webhook configs (URL-based)
│   └── custom/            # Manually maintained resources for remote API server
│       ├── base/
│       └── overlays/
├── components/
│   └── webhook-injector/  # Reusable sidecar Component
├── overlays/              # TOP-LEVEL entry point per environment
│   └── rt-eu-de-1/       # Single kustomization combining host + remote
└── scripts/
    └── wrap-managedresources.sh  # ManagedResource wrapping helper
```

Note: The Makefile targets for regeneration live in `system/Makefile` (not a local Makefile).

## Common Tasks

### Deploy to a cluster

Deploy all resources (host + remote) in a single command:

```bash
kubectl apply -k overlays/rt-eu-de-1/
```

Or preview the rendered output first:

```bash
kustomize build overlays/rt-eu-de-1/
```

This renders all host resources (Deployment, Services, Ingress, etc.) and all remote
ManagedResources (CRDs, RBAC, webhooks) in one output.

### Upgrade upstream metal-operator version

When a new version of `ironcore-dev/metal-operator` is released:

```bash
# 1. Update the pinned git ref in all kustomization files
#    Change ?ref=v0.4.0 → ?ref=v0.5.0 in:
#    - host/base/kustomization.yaml
#    - remote/upstream/crds-and-rbac/kustomization.yaml
#    - remote/upstream/webhooks/source/kustomization.yaml

# 2. Regenerate pre-rendered remote resources (from system/ directory)
make regen-metal-operator-remote

# 3. Review changes
git diff remote/upstream/

# 4. Update image tag in overlays if needed
#    Edit host/overlays/<cluster>/kustomization.yaml → images section

# 5. Commit and push
git add -A && git commit -m "chore: bump metal-operator to v0.5.0"
```

### Regenerate remote resources

Run from `system/` directory after any change to upstream refs or kustomize patches in `remote/upstream/`:

```bash
make regen-metal-operator-remote
```

This rebuilds:
- `remote/upstream/crds-and-rbac/managedresources.yaml`
- `remote/upstream/webhooks/manifests-url-based.yaml`
- `remote/upstream/webhooks/managedresources.yaml`

### Add a new environment overlay

```bash
# 1. Create the overlay directory
mkdir -p host/overlays/<cluster-name>

# 2. Create kustomization.yaml (copy from existing overlay as template)
cp host/overlays/rt-eu-de-1/kustomization.yaml host/overlays/<cluster-name>/

# 3. Edit the overlay with environment-specific values:
#    - Ingress domain (region, clusterType, tld)
#    - Remote apiserver URL
#    - macdb content
#    - Remote CA certificate
#    - Image tags
#    - Controller args (registry URL, etc.)

# 4. If remote custom resources need env-specific values:
mkdir -p remote/custom/overlays/<cluster-name>
# Create kustomization.yaml with IAS group patches

# 5. Verify
kustomize build host/overlays/<cluster-name>/
kustomize build remote/custom/overlays/<cluster-name>/
```

### Preview rendered output for an environment

```bash
# Host resources (what gets deployed to seed)
kustomize build host/overlays/rt-eu-de-1/

# Remote upstream resources (CRDs + RBAC, pre-rendered)
cat remote/upstream/crds-and-rbac/managedresources.yaml

# Remote custom resources (what gets pushed to remote API server)
kustomize build remote/custom/overlays/rt-eu-de-1/
```

### Update webhook-injector image

```bash
# In the environment overlay:
# Edit host/overlays/<cluster>/kustomization.yaml
images:
  - name: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector
    newTag: v0.4.0
```

### Update controller image

```bash
# In the environment overlay:
# Edit host/overlays/<cluster>/kustomization.yaml
images:
  - name: ghcr.io/ironcore-dev/metal-operator-controller-manager
    newTag: sha-abc1234
```

## How Deployment Works

```
Host (seed) cluster:
  kubectl apply -k overlays/<cluster>/  → applies everything in one command

  Or via Flux:
  Flux Kustomization → kustomize build overlays/<cluster>/ → applies to seed

Remote (virtual cluster) API server:
  ManagedResources in seed → GRM controller applies CRDs/RBAC/webhooks to remote API server
```

The remote cluster is a workerless virtual cluster (API server only). The metal-operator controller runs in the seed and reconciles resources in the remote API server. Webhooks use URL-based clientConfig that routes admission requests back to the seed's webhook service.

## Why `make regen` Is Needed (Kustomize Limitations)

Two transformations cannot be expressed in pure kustomize and require scripting:

### 1. ManagedResource wrapping (base64 encoding)

Kustomize cannot take a rendered resource, base64-encode its YAML, and embed it into a
Secret's `data.objects.yaml` field. This is a meta-transformation (turning resources into
data payloads inside other resources). Kustomize has no concept of self-referencing — its
output cannot feed back as input to another resource.

`scripts/wrap-managedresources.sh` handles this.

### 2. Webhook URL composition (string interpolation)

The upstream webhook config uses service-based clientConfig:
```yaml
clientConfig:
  service:
    name: webhook-service
    path: /validate-metal-ironcore-dev-v1alpha1-biossettings
```

We need to compose a URL: `https://metal-operator-webhook-service:443` + the path value.
Kustomize's `replacements` can copy field values but cannot **concatenate strings** or
compose new values from parts of existing values. JSON patches can set static values but
cannot compute them dynamically from other fields. Since each webhook has a different path,
you'd need one patch per webhook (tightly coupled, breaks on upstream changes).

`yq` handles this generically for any number of webhooks.

### Summary of kustomize gaps

| Transformation | Why kustomize can't | Tool used |
|---|---|---|
| Resource → base64 data in Secret | No meta-transformation (resource as payload) | `wrap-managedresources.sh` |
| Compose URL from prefix + field value | No string concatenation in replacements | `yq` |
| Apply transform to N array items generically | No iteration with computed values | `yq` with selector |

These are intentional design limitations — kustomize is declarative configuration patching,
not a general-purpose templating engine.

## Troubleshooting

**`kustomize build` fails with "resource not found"**
- Check that the `?ref=` tag in kustomization.yaml points to a valid upstream git tag
- Verify network access to `github.com/ironcore-dev/metal-operator`

**Role→ClusterRole patch not applying**
- Requires kustomize v5+. Check version with `kustomize version`

**Webhook URL format incorrect after regen**
- Verify `yq` version (v4+ required)
- Check that `remote/upstream/webhooks/source/kustomization.yaml` points to correct upstream ref

**ManagedResource wrapping produces empty output**
- Ensure `scripts/wrap-managedresources.sh` is executable
- Check that `kustomize build` on the input path produces valid multi-document YAML
