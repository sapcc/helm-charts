# ipam-capi-remote-ddo

DDO source.kustomize operand delivery for the ipam-capi-remote (cluster-api-ipam-in-cluster) controller.

## Overview

This is a **source.kustomize** overlay tree (NOT a Helm chart) for dual-deployment-operator (DDO) consumption. The dual-deployment-operator renders the `seed/` overlay for the seed cluster and the `shoot/` overlay for the shoot cluster, and server-side-applies each directly.

## Mode Contract

There is **NO `mode` flag or value**. Mode selection is **structural** — two overlay directories (`seed/`, `shoot/`) each compose:

- `base/` — shared upstream resources that render to BOTH modes
- `additions/<mode>/` — SAP-added, origin-stamped resources specific to each mode

All resources in `additions/seed/` and `additions/shoot/` carry the annotation:

```yaml
dual-deployment-operator.cc.sap/origin: additions
```

This is the kustomize equivalent of the Helm chart `additionsAnnotations` helper.

### Layout

```
system/ipam-capi-remote-ddo/
├── base/                          # Shared upstream resources (renders to BOTH seed + shoot)
│   ├── kustomization.yaml
│   └── upstream-cm.yaml
├── additions/
│   ├── seed/                      # SAP-added seed-only resources (origin: additions)
│   │   ├── kustomization.yaml
│   │   ├── deployment-patch.yaml  # Controller Deployment with r7 webhook-injector
│   │   ├── service.yaml           # Webhook Service ipam-capi-remote-webhook-service
│   │   ├── rbac.yaml              # Webhook-injector RBAC
│   │   ├── metrics.yaml           # Prometheus ServiceMonitor
│   │   ├── token-requestor-secret.yaml
│   │   └── remote-kubeconfig-configmap.yaml
│   └── shoot/                     # SAP-added shoot-only resources (origin: additions)
│       ├── kustomization.yaml
│       └── pools.example.yaml     # Example GlobalInClusterIPPool (unreferenced)
├── seed/                          # Seed overlay: [base, additions/seed]
│   └── kustomization.yaml
├── shoot/                         # Shoot overlay: [base, additions/shoot, crds/*, rbac.yaml, webhooks.yaml]
│   ├── kustomization.yaml
│   ├── crds/                      # 7 vendored CRDs (provider + core CAPI)
│   │   ├── ipam.cluster.x-k8s.io_globalinclusterippools.yaml
│   │   ├── ipam.cluster.x-k8s.io_globalinclusterprefixpools.yaml
│   │   ├── ipam.cluster.x-k8s.io_inclusterippools.yaml
│   │   ├── ipam.cluster.x-k8s.io_inclusterprefixpools.yaml
│   │   ├── ipam.cluster.x-k8s.io_ipaddresses.yaml
│   │   ├── ipam.cluster.x-k8s.io_ipaddressclaims.yaml
│   │   └── cluster.x-k8s.io_clusters.yaml
│   ├── rbac.yaml                  # Controller RBAC (from config/rbac)
│   └── webhooks.yaml              # Webhook configs (Mutating + Validating)
└── tests/                         # Test suite (render_test.sh is the aggregate gate)
    ├── render_test.sh
    ├── crd_diff_test.sh
    ├── rbac_fidelity_test.sh
    ├── no_pool_test.sh
    ├── seed_render_test.sh
    └── webhook_parity_test.sh
```

## Images

Image overrides are applied via the `images:` transformer in `additions/seed/kustomization.yaml` (NOT via CR values like Helm).

| Component | Default | Keppel Override |
|-----------|---------|-----------------|
| Controller | `registry.k8s.io/capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1` | `keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1` |
| Webhook-injector | `ghcr.io/sap-cloud-infrastructure/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976` | `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976` |

## Upstream Update Procedure

When bumping the ipam-capi-remote controller version:

1. **Diff upstream changes**
   ```bash
   # Compare new release tag against current v1.1.1
   git clone https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster
   cd cluster-api-ipam-provider-in-cluster
   git diff v1.1.1..v1.2.0 config/crd/bases config/rbac config/manager
   ```

2. **Re-vendor CRDs** into `shoot/crds/` ONLY if:
   - CRD schema changed (new fields, validation rules)
   - Served versions changed
   - Printer columns changed
   - Conversion webhooks changed
   
   If only labels/annotations/status fields changed, skip re-vendoring.

3. **Eyeball RBAC + Deployment drift**
   - `config/rbac` → `shoot/rbac.yaml`
   - `config/manager` → `additions/seed/deployment-patch.yaml`
   
   Manually merge any new permissions or container args.

4. **Image tag bumps**
   - Update the image tag in the kube-secrets CR (`dualDeploymentOperatorCRs.ipam-capi-remote`)
   - The images transformer in `additions/seed/kustomization.yaml` references the new tag
   - Do NOT re-vendor upstream manifests just for an image tag bump

5. **Run all tests**
   ```bash
   cd system/ipam-capi-remote-ddo
   bash tests/render_test.sh
   bash tests/crd_diff_test.sh
   bash tests/rbac_fidelity_test.sh
   bash tests/no_pool_test.sh
   bash tests/seed_render_test.sh
   bash tests/webhook_parity_test.sh
   ```

## CRD Regeneration

The 7 vendored CRDs in `shoot/crds/` match the **LIVE m-qa-de-200 bundle** field-for-field (normalized: stripped `metadata.resourceVersion`/`uid`/`generation`/`creationTimestamp`/`managedFields`/`ownerReferences` + `status` + Gardener/Helm delivery labels).

### Controller-gen Split

The CRDs have **split controller-gen stamps**:

- 4 provider pool CRDs (GlobalInClusterIPPool, GlobalInClusterPrefixPool, InClusterIPPool, InClusterPrefixPool): `controller-gen v0.17.2`
- 3 core CAPI CRDs (IPAddress, IPAddressClaim, Cluster): `controller-gen v0.21.0`

This matches the upstream [v1.1.1 release](https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster/releases/tag/v1.1.1) commit 7933583138cf.

### Fidelity Enforcement

The `tests/crd_diff_test.sh` script enforces this fidelity by:

1. Fetching live CRDs from m-qa-de-200 shoot cluster
2. Normalizing both live and vendored CRDs (strip volatile fields)
3. Diffing field-for-field

The test **MUST pass** before merging any CRD changes.

### CRD Annotations

All 7 CRDs carry the upstream labels:

```yaml
metadata:
  labels:
    clusterctl.cluster.x-k8s.io/move-hierarchy: ""
    cluster.x-k8s.io/provider: ipam-in-cluster
```

The 2 provider pool CRDs (GlobalInClusterIPPool, GlobalInClusterPrefixPool) also carry the cert-manager CA-injection annotation (for admission webhooks):

```yaml
metadata:
  annotations:
    cert-manager.io/inject-ca-from: ipam-system/ipam-serving-cert
```

## Data CRs (GlobalInClusterIPPool)

The 2 live out-of-band pools on m-qa-de-200 are **NOT chart-delivered**:

- `globalinclusterippool-mgmt-qa-de-200` (UID 83614ed7-f367-4bd0-acdd-4fbd4de76eec, 10.219.139.128/26, 1 allocation)
- `test` (UID d7d99994-c27d-4116-835b-4d858069b7ea, 0 used)

The a-qa-de-200 CR sets NO pools, so `shoot/` overlay **omits** `additions/shoot/pools.example.yaml` from resources.

## Testing

The test suite validates:

- **render_test.sh**: Aggregate gate — both overlays build cleanly, mode-isolation assertions (seed has Deployment + webhook-injector RBAC + Service, zero CRDs; shoot has all 7 CRDs + controller RBAC + both webhook configs, zero Deployment/Service)
- **crd_diff_test.sh**: CRD fidelity against live m-qa-de-200 bundle
- **rbac_fidelity_test.sh**: RBAC role/binding completeness
- **no_pool_test.sh**: Shoot overlay builds when no pools are in resources
- **seed_render_test.sh**: Seed Deployment has r7 webhook-injector sidecar with correct args
- **webhook_parity_test.sh**: Both webhook configs rendered identically in shoot

Run all tests before merging:

```bash
cd system/ipam-capi-remote-ddo
for test in tests/*.sh; do
  echo "=== Running $test ==="
  bash "$test" || exit 1
done
```

## Deployment

The dual-deployment-operator:

1. Git-clones this repo at `?ref=<tag>`
2. Runs `kustomize build seed/` → SSA to seed cluster
3. Runs `kustomize build shoot/` → SSA to shoot cluster
4. Parses the `dual-deployment-operator.cc.sap/origin` annotation to distinguish upstream vs. SAP-added resources
5. Applies `shootNamespace: kube-system` to all shoot resources (skipping CRDs/ClusterRole(Binding)/webhook-configs)

The CR lives in kube-secrets:

- Base: `values/helm/admin-k3s/dual-deployment-operator.yaml` (dualDeploymentOperatorCRDefaults.ipam-capi-remote)
- Overlay: `values/helm/admin-k3s/qa-de-1/a-qa-de-200/dual-deployment-operator.yaml` (dualDeploymentOperatorCRs.ipam-capi-remote)

### CR Fields

```yaml
source:
  kustomize:
    url: https://github.com/sapcc/helm-charts
    ref: <tag>
    seedPath: system/ipam-capi-remote-ddo/seed
    shootPath: system/ipam-capi-remote-ddo/shoot
shootAccess:
  server: https://api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap
shootNamespace: kube-system
applyOrder: SeedFirst
```

## Identities (load-bearing)

These names are **load-bearing** (`fullnameOverride: ipam-capi` in legacy Helm chart):

- Deployment: `ipam-capi-controller-manager`
- Shoot controller ServiceAccount: `ipam-capi-controller-manager` (namespace: kube-system)
- Webhook-injector ServiceAccount: `ipam-capi-remote-webhook-injector` (namespace: kube-system, seed-only)
- Webhook Service: `ipam-capi-remote-webhook-service` (seed-only)
- Webhook configs:
  - `ipam-capi-remote-mutating-webhook-configuration` (shoot-only)
  - `ipam-capi-remote-validating-webhook-configuration` (shoot-only)
- Selector: `control-plane: controller-manager`, `app.kubernetes.io/name: ipam-capi-remote`

Do NOT rename these without coordinating with the live cluster state and the dual-deployment-operator CR.
