# AGENTS.md

## Overview

Monorepo of Helm charts for SAP Converged Cloud infrastructure. ~200+ charts grouped by domain. Default branch is `master`.

## Repository Structure

```
common/              # Reusable library charts (mariadb, rabbitmq, prometheus-server, etc.)
global/              # Singleton charts deployed once globally
openstack/           # OpenStack services and related components
prometheus-exporters/# Prometheus exporter charts
prometheus-rules/    # Prometheus alert and aggregation rules
px/                  # Network/routing charts (bird, arp-discovery)
system/              # Control-plane infrastructure charts
ci/                  # Chart-testing configuration and lint scripts
```

Each top-level directory is a `chart-dir` for `ct` (chart-testing). Charts live one level below (e.g., `system/calico/`).

## Chart Conventions

- `Chart.yaml` must use `apiVersion: v2`
- **Version bumps are enforced**: CI checks that chart versions increment on change. The OCI registry (`ghcr.io/sapcc/helm-charts/`) rejects duplicate versions.
- Charts deploy to a namespace matching their name (e.g., `system/dns` → namespace `dns`)
- Test values go in `<chart>/ci/*-values.yaml` (used by `ct lint`)
- Unit tests go in `<chart>/tests/*_test.yaml` (run with `helm-unittest`)

## CI (GitHub Actions on PRs)

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `helm-unittest` | All PRs | Runs `helm unittest` on changed charts that have a `tests/` dir |
| `check-chart-version` | PRs touching `system/` or `global/cc-gardener/` | Enforces version bump for ControlPlane-owned charts |
| `helm-lint` | Manual only (disabled—can't resolve internal deps) | `ct lint` with schema validation |
| `helm-push` | Push to `master` (only `common/postgresql-ng` and `common/linkerd-support`) | Packages and pushes to OCI registry |

## Local Development Commands

### Lint a single chart

```bash
ci/lint-chart.sh <chart-path>
# Example: ci/lint-chart.sh openstack/nova
```

Uses Docker image `sapcc/chart-testing:v3.8.0-sapcc`. Alternatively:

```bash
docker run --rm -v $(pwd):/charts sapcc/chart-testing:latest sh -c \
  "cd charts && ct lint --chart-yaml-schema ci/chart_schema.yaml --lint-conf ci/lintconf.yaml --config ci/config.yaml --charts <chart-path>"
```

### Run unit tests for a chart

```bash
helm unittest <chart-path>
```

Requires the `helm-unittest` plugin:
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

### Build CAPI/operator charts (system/ only)

```bash
make -C system build-<target>
```

Requires: `kubectl`, `kustomize`, `helmify`, `yq`, and on macOS `gsed` (GNU sed).

## YAML Lint Rules (ci/lintconf.yaml)

- Indentation: consistent (no fixed count enforced)
- `indent-sequences: whatever` — both styles accepted
- Line length: disabled
- Trailing spaces: disabled
- Truthy values: warning only
- Newlines: unix (`\n`)

## Kustomize Overlays (system/kustomize/)

Some operators in `system/` use a pure kustomize overlay structure instead of the `helmify`-based Makefile pipeline. This is the preferred pattern for Flux-compatible deployments.

### Structure

```text
system/kustomize/<operator>/
├── overlays/
│   ├── host/          # Resources for the seed (host) cluster: Deployment, ConfigMap
│   └── remote/        # Resources for the shoot (remote) cluster: CRDs, RBAC
│       ├── crd/
│       └── rbac/
└── components/        # Reusable kustomize components (kind: Component)
    ├── webhook-injector/       # Adds webhook-injector native sidecar
    ├── clusterrole-conversion/ # Converts Role/RoleBinding → ClusterRole/ClusterRoleBinding
    └── namespace-strip/        # Removes namespace from Deployment (reference)
```

### Design decisions

- **No shared base**: host and remote overlays need non-overlapping resource subsets from upstream. Each overlay references its specific upstream sub-directory directly (e.g., `config/manager`, `config/crd`, `config/rbac`). A single `config/default` base would require KRM plugins to filter resources, which are Flux-incompatible.
- **`patches:` with `target:` required (not `patchesStrategicMerge`)**: In kustomize v5, `patchesStrategicMerge` matches resources by namespace too. When a patch file has no `namespace:` field but the upstream resource has `namespace: system`, kustomize reports `no matches for Id ... [noNs]`. Use `patches: [{path: ..., target: {kind: ..., name: ...}}]` instead — `target:` matching ignores namespace.
- **Component processing order**: Components run *before* overlay `namePrefix`/`namespace` transformers. Patches in components must target pre-prefix resource names (e.g., `controller-manager`, not `metal-operator-controller-manager`).
- **configMapGenerator + namePrefix**: A `configMapGenerator` name gets the overlay `namePrefix` applied. If the sidecar references the ConfigMap by name, override that arg in an overlay-level patch (not in the component patch).

### Verification

```bash
# Build host overlay (Deployment + ConfigMap → seed cluster)
kubectl kustomize system/kustomize/metal-operator/overlays/host

# Build remote overlay (CRDs + RBAC → shoot cluster)
kubectl kustomize system/kustomize/metal-operator/overlays/remote
```

Requires `kubectl` (bundles kustomize v5.8.1+). Upstream GitHub URLs are fetched at build time.

## Key Gotchas

- **Internal dependencies can't be resolved in CI** — `helm-lint` workflow is disabled for this reason. Charts referencing other charts in this repo won't lint cleanly in isolation.
- **CODEOWNERS is extensive** — check `.github/CODEOWNERS` before modifying charts owned by other teams.
- Prometheus rules files use `.alerts` and `.rules` extensions and are validated with `promtool`.
- The `system/Makefile` generates charts from upstream kustomize configs using `helmify`. These charts are auto-generated — edit the Makefile targets, not the generated output. New operators should use the kustomize overlay pattern instead (see above).
- OCI push only happens for specific charts (`common/postgresql-ng`, `common/linkerd-support`). Most charts are consumed via other mechanisms.
