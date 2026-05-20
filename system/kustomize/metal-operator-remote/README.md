# metal-operator-remote (Kustomize)

Kustomize-based deployment of the metal-operator in a split host/remote cluster setup. Replaces the previous Helm chart at `system/metal-operator-remote/`.

This repository owns only the **bases, components, and upstream pre-renders**. Per-cluster overlays live in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets) and reference these bases via kustomize Git URL refs (`?ref=master`). See [Per-cluster overlays](#per-cluster-overlays).

## Prerequisites

- `kustomize` v5+ (for `patches[].target.kind` matching)
- `yq` v4+ (for webhook URL regeneration)
- `kubectl` (for verification)

## Directory Layout

```
.
├── host/
│   └── base/              # Shared host-side resources for all environments
├── remote/
│   ├── upstream/          # Generated from upstream ironcore-dev/metal-operator
│   │   ├── crds-and-rbac/ # CRDs + RBAC for remote API server
│   │   └── webhooks/      # Webhook configs (URL-based)
│   └── custom/            # Manually maintained resources for remote API server
│       ├── base/
│       └── components/
│           ├── prod/
│           └── qa/
├── components/
│   └── webhook-injector/  # Reusable sidecar Component
└── scripts/
    └── wrap-managedresources.sh  # ManagedResource wrapping helper
```

Note: The Makefile targets for regeneration live in `system/Makefile` (not a local Makefile).

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

Changes to `host/base/`, `remote/custom/base/`, components, or upstream pre-renders in this repository are picked up automatically by kube-secrets overlays at the next `kustomize build` (since they track `?ref=master`). Apply normal change-management in this repository (PR review, OpenSpec change for spec-level requirements).

Tracking: [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169)

## Common Tasks

### Preview a base or component

```bash
# Host base (deployment, services, ingress template, etc.)
kustomize build system/kustomize/metal-operator-remote/host/base/

# Remote custom base (resources sent to the remote API server)
kustomize build system/kustomize/metal-operator-remote/remote/custom/base/

# Remote upstream pre-renders (already-rendered ManagedResource secrets)
cat system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml
cat system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml
```

To preview a complete cluster overlay (host + remote combined), build it from `cc/kube-secrets`:

```bash
kustomize build <kube-secrets-checkout>/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/
```

### Upgrade upstream metal-operator version

When a new version of `ironcore-dev/metal-operator` is released:

```bash
# 1. Update the pinned git ref in all upstream kustomization files
#    Change ?ref=v0.4.0 → ?ref=v0.5.0 in:
#    - host/base/kustomization.yaml
#    - remote/upstream/crds-and-rbac/kustomization.yaml
#    - remote/upstream/webhooks/source/kustomization.yaml

# 2. Regenerate pre-rendered remote resources (from system/ directory)
make regen-metal-operator-remote

# 3. Review changes
git diff remote/upstream/

# 4. Commit and push
git add -A && git commit -m "chore: bump metal-operator to v0.5.0"
```

Per-cluster image tags (controller, webhook-injector) are pinned in the kube-secrets overlays — update them there if needed, not here. See `cc/kube-secrets/values/kustomize/.../metal-operator-remote/host/kustomization.yaml`.

### Regenerate remote resources

Run from `system/` directory after any change to upstream refs or kustomize patches in `remote/upstream/`:

```bash
make regen-metal-operator-remote
```

This rebuilds:
- `remote/upstream/crds-and-rbac/managedresources.yaml`
- `remote/upstream/webhooks/manifests-url-based.yaml`
- `remote/upstream/webhooks/managedresources.yaml`

## How Deployment Works

```
cc/kube-secrets per-cluster overlay (?ref=master in helm-charts)
  │
  ├─ host/   → Host (seed) cluster:
  │            Flux Kustomization → kustomize build → applies to seed
  │            (Deployment, Services, Ingress, webhook-injector sidecar)
  │
  └─ remote/ → ManagedResources in seed
                → GRM controller applies CRDs/RBAC/webhooks
                  to remote (virtual) cluster API server
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

**`kube-secrets` overlay fails with "new root cannot be absolute"**
- You probably tried to substitute github.com URLs with absolute filesystem paths during local validation. kustomize requires **relative** paths in `resources:` entries. Use `os.path.relpath` (Python) or compute the right number of `..` levels manually, and build with `kustomize build --load-restrictor=LoadRestrictionsNone`. See the kube-secrets `values/kustomize/README.md` for the correct local-validation recipe.

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
