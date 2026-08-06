# metal-operator-remote-v2 — Examples

This directory contains example `DualDeploymentOperator` CRs for operating the
`metal-operator-remote-v2` chart via the
[dual-deployment-operator](https://github.com/SAP-cloud-infrastructure/dual-deployment-operator).

## Examples

| File | Cluster | Purpose |
|------|---------|---------|
| `dualdeploymentoperator-a-qa-de-200.yaml` | a-qa-de-200 (qa-de-1) | QA reference CR, vault+kvv2 macdb refs, both transforms |
| `shoot-m-test-1.yaml` | m-test-1 (qa-de-1) | Throwaway workerless metalapi Shoot for testing, modeled on prod `m-qa-de-1` |

## Testing on a throwaway shoot (do NOT touch prod `m-qa-de-1`)

`metal-operator-remote` is a per-region singleton: the controller runs in the seed
CP namespace `shoot--cp--m-<region>` (on seed `rt-<region>`) and manages the region's
single metalapi shoot `m-<region>` remotely. To test `-v2` without disrupting the live
`m-qa-de-1`, create a separate workerless shoot and point a test CR at it.

1. **Create the shoot**: apply `shoot-m-test-1.yaml` in the garden cluster
   (`g-qa-de-1`, project `cp`, namespace `garden`) via the dashboard YAML editor or
   `u8s kubectl --context g-qa-de-1 -n garden apply -f shoot-m-test-1.yaml`.
2. **Read the assigned apiserver host** after it goes healthy:
   `u8s kubectl --context g-qa-de-1 -n garden get shoot m-test-1 -o jsonpath='{.spec.dns.domain}'`
   → `api.m-test-1.cp.external.rt-qa-de-1.soil-garden.qa-de-1.cloud.sap`.
3. **Copy the a-qa-de-200 CR** and swap the three cluster-identity fields for the test shoot:
   - `metadata.namespace` → `shoot--cp--m-test-1` (the seed CP namespace)
   - `shootAccess.server` and `values.controllerManager.manager.env.KUBERNETES_SERVICE_HOST`
     → `https://<the apiserver host from step 2>`
   - `virtualGardenLBIP` → the test seed's LB IP
4. **Teardown order**: delete the operator CR on the seed FIRST (lets the operator tear
   down what it applied), THEN delete the shoot from the dashboard.

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
