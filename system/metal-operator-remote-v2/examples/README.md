# metal-operator-remote-v2 — Examples

This directory contains example `DualDeploymentOperator` CRs for operating the
`metal-operator-remote-v2` chart via the
[dual-deployment-operator](https://github.com/SAP-cloud-infrastructure/dual-deployment-operator).

## Examples

| File | Cluster | Purpose |
|------|---------|---------|
| `dualdeploymentoperator-a-qa-de-200.yaml` | a-qa-de-200 (qa-de-1) | QA reference CR, vault+kvv2 macdb refs, both transforms |

## Prerequisites

Before deploying any example CR:

1. **Operator version**: `dual-deployment-operator` on `main` at or after commit `c37a676`
   (patch render-scoping / silent no-op on zero matches). The label `patch` transform
   requires this to avoid `SeedTransformFailed` on the seed render.

2. **`applyOrder: SeedFirst`** is set in all examples — mandatory because the
   `metal-operator-remote-kubeconfig` shootAccess Secret is produced by the seed render
   and must exist before the operator reads it.

3. **Replace placeholders** — values marked `<...>` must be filled with real per-cluster
   values before deploying (KUBERNETES_SERVICE_HOST, shoot server URL, registry URL, etc.).

4. **macdb refs** — the `vault+kvv2://` strings in `macdb.macPrefixes[].defaultCredentials`
   are resolved in-cluster by the secrets-injector webhook on the seed; they must NOT be
   replaced with real credentials in git.

## Subchart dependency note

The `metal-operator-remote-v2` chart declares the `metal-operator` upstream chart as an OCI
dependency in `Chart.yaml` and commits only `Chart.lock` (not `charts/*.tgz`). The publish
workflow runs `helm dependency update && helm package && helm push`; the resulting published
artifact bundles the subchart so the operator can pull a complete chart without resolving
dependencies itself. See the operator docs:
`docs/subchart-dependency-resolution.md` in the `dual-deployment-operator` repo.
