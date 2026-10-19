# DISCO — Designate IngresS Cname Operator

[DISCO](https://github.com/sapcc/disco) automatically discovers Ingresses in a Kubernetes cluster
and creates corresponding CNAMEs in OpenStack Designate.

## Deployment modes

The chart supports two deployment modes controlled by `remote.enabled`.

### Local mode (`remote.enabled: false`, default)

The controller runs in and manages the same cluster. RBAC, the CRD, and the ServiceAccount are all
installed into the release namespace / cluster-scoped as normal Helm resources.

```
┌─────────────────────────────────┐
│  Cluster                        │
│                                 │
│  disco pod ──watches──► Ingress │
│      │                          │
│      └──creates──► Designate    │
└─────────────────────────────────┘
```

**Minimum values:**

```yaml
record: ingress.example.com.

openstack:
  authURL: https://identity.example.com/v3
  regionName: example
  username: disco
  userDomainName: Default
  password: <secret>
  projectName: cloud_admin
  projectDomainName: Default
  zoneName: example.com.
```

### Remote mode (`remote.enabled: true`)

The controller runs in a **garden cluster** (seed) but manages Ingresses and Designate records on a
remote **shoot cluster**. This is the Gardener use case.

```
┌─────────────────────────────────────────────────────────────────┐
│  Garden cluster (seed)                                          │
│                                                                 │
│  disco pod ──KUBERNETES_SERVICE_HOST──► shoot API server        │
│                                                  │              │
│  disco-remote-kubeconfig Secret                  │              │
│    (token injected by Gardener ResourceManager)  │              │
└──────────────────────────────────────────────────┼──────────────┘
                                                   │
┌──────────────────────────────────────────────────▼──────────────┐
│  Shoot cluster                                                  │
│                                                                 │
│  kube-system/disco-controller-manager SA  ◄── ManagedResource   │
│  RBAC (ClusterRoles, Roles, Bindings)     ◄── ManagedResource   │
│  CRD records.disco.stable.sap.cc          ◄── ManagedResource   │
│                                                                 │
│  disco pod ──watches──► Ingress                                 │
│      │                                                          │
│      └──creates──► Designate                                    │
└─────────────────────────────────────────────────────────────────┘
```

In remote mode the chart emits two Gardener `ManagedResource` objects. Gardener's ResourceManager
picks these up and applies the contained resources to the shoot cluster:

| ManagedResource | Contents |
|---|---|
| `disco-crd` | `CustomResourceDefinition` — `records.disco.stable.sap.cc` |
| `disco-rbac` | `ServiceAccount`, `ClusterRole`s, `ClusterRoleBinding`s, `Role`, `RoleBinding` — all scoped to `remote.shootNamespace` |

RBAC and the CRD are **not** installed into the garden cluster in remote mode. The `ServiceAccount`
is created in both clusters: locally for the pod, and on the shoot via `disco-rbac` for RBAC and
token-requestor purposes.

Gardener's token-requestor injects a short-lived shoot cluster token and CA bundle into the
`disco-remote-kubeconfig` Secret, which the pod mounts as its kubeconfig.

**CRD installation:** Because the CRD lives in `crds/`, Helm installs it by default. When deploying
in remote mode you should skip local CRD installation (`--skip-crds` / `includeCRDs: false`) since
the CRD is managed on the shoot cluster via the `disco-crd` ManagedResource.

**Minimum additional values for remote mode:**

```yaml
remote:
  enabled: true
  apiServerHost: kube-apiserver.shoot--<project>--<name>.svc.cluster.local
  # shootNamespace: kube-system  # default — namespace on the shoot cluster for SA and RBAC
```

## Requirements

- `cert-manager >= v1.0.0` for the webhook TLS certificate
- Remote mode only: Gardener ResourceManager running in the garden cluster

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `record` | CNAME record to create. e.g. `ingress.domain.tld.` | `` |
| `ingressAnnotation` | Only Ingresses with this annotation are considered | `disco` |
| `openstack` | OpenStack Designate credentials. See [values.yaml](./values.yaml) | `{}` |
| `seed.enabled` | Create an OpenStack seed for the service user | `false` |
| `rbac.create` | Create RBAC resources (suppressed in remote mode — handled via ManagedResource) | `true` |
| `serviceAccount.create` | Create the ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | `disco-controller-manager` |
| `certManager.enabled` | Create cert-manager Issuer and Certificate for webhook TLS | `true` |
| `webhooks.enabled` | Create webhook Service and MutatingWebhookConfiguration | `true` |
| `metrics.enabled` | Create the metrics Service | `true` |
| `metrics.port` | Metrics port | `8080` |
| `metrics.prometheus` | Prometheus scrape target name | `kubernetes` |
| `reloader.enabled` | Reload controller when `disco-config` Secret changes | `true` |
| `controllerLabels` | Extra labels on the controller Deployment (e.g. Gardener network policies) | `{}` |
| `remote.enabled` | Enable remote (Gardener shoot) mode | `false` |
| `remote.apiServerHost` | Shoot API server hostname (required when `remote.enabled: true`) | `` |
| `remote.apiServerPort` | Shoot API server port | `443` |
| `remote.shootNamespace` | Namespace on the shoot cluster for SA, RBAC, and leader election lease | `kube-system` |

For all parameters see [values.yaml](./values.yaml).
