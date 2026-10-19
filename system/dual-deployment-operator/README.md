# dual-deployment-operator (wrapper chart)

Per-shoot wrapper chart that deploys the `dual-deployment-operator` controller onto a seed
cluster and bootstraps the shoot side so the operator can reach it.

One Helm release per `shoot--cp--<name>` namespace. The wrapper depends on the published
upstream controller chart (OCI) via a subchart alias `controller`; all upstream values live
under `controller.*`.

## What this chart delivers

| Resource | Where | Purpose |
|---|---|---|
| Operator Deployment + RBAC | seed (`shoot--cp--<name>`) | Runs the controller |
| `DualDeploymentOperator` CRD | seed (cluster-scoped) | Owned by the prod release |
| `ManagedResource` `dual-deployment-operator-shoot-rbac-bootstrap` | seed | GRM applies shoot-applier SA + ClusterRole/Binding to the shoot |
| `Secret` `dual-deployment-operator-shoot-access` | seed (`shoot--cp--<name>`) | Gardener token-requestor; mints the shoot kubeconfig the operator uses |

## Chart structure

```
dual-deployment-operator/          # this wrapper (sapcc/helm-charts)
  Chart.yaml                       # dependency: dual-deployment-operator OCI chart, alias: controller
  values.yaml                      # defaults; per-shoot overrides in cc/kube-secrets
  templates/                       # (future: DualDeploymentOperator CR instances)
```

The upstream chart is declared as a subchart with alias `controller`:

```yaml
# Chart.yaml
dependencies:
  - name: dual-deployment-operator
    repository: oci://keppel.eu-de-2.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/helm-dual-deployment-operator
    version: "0.1.0"
    alias: controller
    condition: controller.enabled
```

All upstream values are therefore nested under `controller`:

```yaml
controller:
  manager:
    image:
      repository: keppel.eu-de-2.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/dual-deployment-operator@sha256:<digest>
  shootRbac:
    enabled: true
    serviceAccountName: dual-deployment-operator-shoot-applier
    serviceAccountNamespace: kube-system
```

## Required overrides and why

### Image digest pin

```yaml
controller:
  manager:
    image:
      repository: keppel.eu-de-2.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/dual-deployment-operator@sha256:66e753a85c99b6210fc875a179964d89e940c95f29eb9c07c18efcc613a6567e
      pullPolicy: IfNotPresent
```

The seed pulls from the keppel mirror. Pinning by digest (not tag) is mandatory for
reproducible rollouts. The `@sha256:` in the repository field suppresses any `:tag`
suffix (manager.yaml:106 `contains "@"` guard).

### Disable webhooks

```yaml
controller:
  manager:
    envOverrides:
      ENABLE_WEBHOOKS: "false"
```

The controller chart ships a validating admission webhook. Without a TLS certificate the
webhook server fails to start and the pod crashloops. cert-manager is not available in
this environment, so webhooks must be disabled at startup via `ENABLE_WEBHOOKS=false`.

### Disable secure metrics

```yaml
controller:
  metrics:
    enabled: false
```

Secure metrics require a serving certificate. Same reason as above: no cert-manager, so
the metrics endpoint must be disabled.

### Shoot-ready bootstrap

```yaml
controller:
  shootRbac:
    enabled: true
    serviceAccountName: dual-deployment-operator-shoot-applier
    serviceAccountNamespace: kube-system
```

When `shootRbac.enabled: true` the chart emits two resources:

1. **GRM `ManagedResource`** `dual-deployment-operator-shoot-rbac-bootstrap` — Gardener
   Resource Manager applies a `ServiceAccount`, `ClusterRole`, and `ClusterRoleBinding`
   to the shoot cluster, giving the operator's shoot identity broad apply permissions.
2. **`Secret`** `dual-deployment-operator-shoot-access` — a Gardener token-requestor
   Secret. Gardener populates it with a kubeconfig that authenticates as the SA named
   above. The operator reads this Secret for its shoot client.

`serviceAccountName: dual-deployment-operator-shoot-applier` and
`serviceAccountNamespace: kube-system` are static per release. Because this chart is
installed once per shoot cluster, the static SA name is unique per shoot — there is no
cross-shoot collision.

## CRD lifecycle (critical)

The `DualDeploymentOperator` CRD (`dualdeploymentoperators.dual-deployment-operator.cc.sap`)
is a **Helm template** (under `templates/crd/`), not a `crds/` directory entry. This means:

- The CRD rolls out on `helm upgrade` of whichever release owns it.
- It carries `helm.sh/resource-policy: keep`, so `helm uninstall` orphans it rather than
  deleting it (protecting live CR instances).

### Durable CRD owner

The **production release** (`shoot--cp--m-<region>`) is the durable CRD owner. It sets:

```yaml
controller:
  crd:
    enabled: true   # this release owns the CRD
```

**Never flip the owner release to `crd.enabled: false`.** Because the CRD carries
`resource-policy: keep`, Helm will orphan it on the next upgrade of that release. Once
orphaned, no release manages the CRD and it will never be upgraded again.

All non-owner releases (smoke, canary, etc.) set:

```yaml
controller:
  crd:
    enabled: false  # CRD managed by the prod release; skip here
```

### Bootstrap order

1. Deploy the **prod (owner) release first** — installs the CRD as a Helm-managed resource.
2. Deploy non-owner releases after — they skip the CRD template.

Reversing this order means non-owner releases render CR instances before the CRD exists,
causing `helm install` to fail.

### Upgrade runbook

1. Bump the subchart version in `Chart.yaml`.
2. Roll the **owner release first** (`helm upgrade` on the prod release) — upgrades the CRD.
3. Verify the live CRD version matches the new schema (`kubectl get crd dualdeploymentoperators.dual-deployment-operator.cc.sap -o yaml`).
4. Roll non-owner releases.

## Multi-install-per-seed

Multiple releases of this chart can coexist on the same seed (one per shoot namespace)
because:

- **RBAC** (`ClusterRole`, `ClusterRoleBinding`) is release-scoped — names include the
  release namespace, so installs don't collide.
- **CRD** is seed-scoped (cluster-wide, one name). Only the owner release manages it;
  all others set `crd.enabled: false`.

## Delivery

Charts are delivered via `cc/kube-secrets` through the Concourse `helm-chart-pipeline`.
Each shoot gets a values file at:

```
values/helm/<region>/dual-deployment-operator.yaml
```

The pipeline installs/upgrades the release into namespace `shoot--cp--m-<region>`.

## Adding a shoot

Add a values file for the new shoot in `cc/kube-secrets`. No pipeline changes needed —
the existing `helm-chart-pipeline` picks up new values files automatically.

```yaml
# values/helm/runtime/qa-de-1/<new-seed>/dual-deployment-operator.yaml
controller:
  manager:
    envOverrides:
      ENABLE_WEBHOOKS: "false"
  metrics:
    enabled: false
  shootRbac:
    enabled: true
    serviceAccountName: dual-deployment-operator-shoot-applier
    serviceAccountNamespace: kube-system
  crd:
    enabled: false   # prod release owns the CRD; set true only on the prod release
```

## Non-goals

- This chart does **not** render `DualDeploymentOperator` CR instances (workload delivery).
  Those live in a separate wrapper chart or are applied directly.
- This chart does **not** manage metal-operator, ipam-capi, or any other operator's CRs.
- This chart does **not** use the `-v2` scaffold or any `-remote` suffix.
