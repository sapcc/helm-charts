# ipam-capi-remote-ddo

A **DDO source.kustomize operand**, not a Helm chart. DDO renders `seed/` and
`shoot/` independently and server-side-applies each to its respective cluster.

## Release gate

**Do not activate this candidate based only on these static tests.** Deploy a
DDO release supporting safely acquired, SHA-pinned Git directory bases and
`spec.source.kustomize`, plus an admin chart that renders that source type.
There are **no raw HTTP resources**: the three core CRDs are vendored verbatim;
the real provider Git directory remains remote. Do not relax DDO preflight.
An online CLI build is not evidence of production cache/offline semantics.

Before cutover: independently verify DDO integration, the required seed binding
transformation below, current shoot credentials, initial CA stamping and rotation,
and shoot-apiserver reachability/TLS to the legacy short webhook URL. Preserve
the out-of-band pools and coordinate old/new injector ownership. Runtime target
mode patches CA only; it does not create targets or repair their URLs. Publish
the required operator/chart releases and review the complete downstream CR
transformation list before activating kube-secrets PR #5683 / migration PR #13218.
No live connectivity, upgrade or rotation safety is established by this suite.

## Structural mode contract

There is no `mode` value. `seed/` composes `../base` and `../additions/seed`;
`shoot/` composes `../base`, `../additions/shoot`, its remote CRD sources, RBAC,
and webhook configurations. `base/` is currently empty; anything added there
renders to **both** clusters. SAP-added resources carry:

```yaml
dual-deployment-operator.cc.sap/origin: additions
```

## Layout

```text
system/kustomize/ipam-capi-remote-ddo/
  base/kustomization.yaml
  additions/seed/
    deployment.yaml
    kustomization.yaml
    remote-kubeconfig-secret.yaml
    remote-kubeconfig-configmap.yaml
    webhook-service.yaml
    webhook-injector-rbac.yaml
    webhook-injector-metrics-service.yaml
    webhook-injector-servicemonitor.yaml
    networkpolicies.yaml               # three migration-inventory NetworkPolicies
    manager-config.yaml                # manager ConfigMap (migration inventory)
  additions/shoot/
    kustomization.yaml
    pools.example.yaml                 # unreferenced example
  seed/kustomization.yaml
  shoot/
    kustomization.yaml                 # provider Git base + core-crds + local RBAC/webhooks
    core-crds/                         # three exact pinned files + provenance README
      kustomization.yaml               # local resources + explicit conversion default
    patches/conversion-*.yaml           # four SAP pool conversion shims
    rbac.yaml
    webhooks.yaml
    metrics-service.yaml               # controller metrics Service (migration inventory)
  tests/
    crd-baseline.json                   # compact immutable render fingerprints
    crd_parity.py
    migration_render.py                # independent pinned Helm oracle
    migration_contract.py              # guarded deltas + mutation tests
    *_test.sh
```

## Upstream sources and SAP deltas

| Origin | Release | Resolved commit | Delivered objects |
| --- | --- | --- | --- |
| kubernetes-sigs/cluster-api-ipam-provider-in-cluster | v1.1.1 | `7933583138cf1b5b16b6a1dd82a804729f83afab` | Four pool CRDs through `//config/crd?ref=<SHA>` |
| kubernetes-sigs/cluster-api | v1.14.2 | `5f7d58c9ad647f31bd342bf8de33092c27f7fc38` | Exactly Cluster, IPAddress, IPAddressClaim vendored in `shoot/core-crds/` |

Git directory bases require a kustomization directory. See
[core provenance and SHA-256 checksums](shoot/core-crds/README.md) for the exact
three upstream files. Do not import CAPI's entire CRD directory: it introduces
ten additional CRDs this operand does not own.

The four pool patches preserve URL-only conversion to
`https://ipam-capi-remote-webhook-service:443/convert` and review version `v1`.
There is **no static CA**. `clientConfig.service: null` explicitly removes the
upstream service reference. The three core sources omit `conversion`; a small
patch restores the existing explicit `{strategy: None}` default. No upstream
schema is changed. All four pools and both admission configurations carry
`dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote`, matching
exactly one injector `--target-label` argument. Core CRDs are not targeted.
The injector owns CA dynamically; DDO must continue stripping only the CA leaf
before SSA. The short URL and `--cert-sans=ipam-capi-remote-webhook-service`
preserve the legacy topology; they do not prove that the endpoint is reachable.

Pool CRDs retain controller-gen v0.17.2 and the empty
`clusterctl.cluster.x-k8s.io/move-hierarchy` label. Core CRDs retain v0.21.0 and
no move-hierarchy label. Provider and cert-manager injection metadata are absent.

### Accepted maximize-upstream scope

This candidate fetches four CRDs and vendors three. The existing `shoot/rbac.yaml`
stays local: importing the full upstream RBAC base adds unwanted objects and
namespaced leader-election roles instead of the existing remote cluster-scoped
variant. It also contains SAP metal cross-operator bindings and webhook-injector
permissions. Only the shoot injector role changes: named `get,patch` for the
four pool CRDs and each admission configuration, plus separate unrestricted
`list,watch` for informer discovery. Label selection is **not RBAC authorization**.
No target `create/update` rights are needed. The binding still grants these
rights to `ipam-capi-controller-manager/kube-system`, so manager and injector
share credentials. Unrelated manager roles and seed permissions are unchanged.
The URL-based webhook configurations, seed remote-controller wiring, and pool
example remain local. This is the accepted
CRD-only scope, not a prohibition on future selective upstream RBAC/manager
refactoring with its own parity checks.

## Images and per-cluster configuration

Images are overridden with `images:` in `additions/seed/kustomization.yaml`, not
Helm values:

- Controller: `registry.k8s.io/capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`
  → `keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1`.
- Injector: `ghcr.io/sap-cloud-infrastructure/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976`
  → `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector` with the same tag.

The shared seed kubeconfig and manager host retain neutral placeholders.
Per-cluster kube-secrets CR transformations supply the actual kubeconfig server
and `KUBERNETES_SERVICE_HOST`. All six target labels are already in source.
`shootAccess.server` configures DDO's client, not the operand's mounted kubeconfig.

## Maintenance and fidelity

1. Resolve a new upstream release tag to its **commit**, not its tag object.
2. Review upstream schema, served/storage versions, conversion, RBAC and manager
   changes against the current pins. Update Git pins and vendored bytes/checksums coherently.
3. Review conversion patches and any necessary local RBAC/Deployment changes.
   Image tags are maintained separately via `images:`.
4. Run the complete suite. Intentional schema changes require explicit baseline
   review; never regenerate fingerprints automatically to hide a mismatch.
5. Review the source-pin and fingerprint diff together before deployment.

`tests/crd-baseline.json` is an **unchanged historical reference**, not a regenerated
approval of this repair. Its file hash is guarded. Tests first render the actual
Helm chart at `97d52c25ae067c00fd5f5b3e7a66771fdcbc10db`, unwrap ManagedResources
and the webhook ConfigMap, and require its exact **15 seed / 25 shoot identities**.
Independent nonsecret input values pin the same images/security settings as the
candidate. No live capture is needed; those Git commits must exist locally.

The only guarded migration deltas are: core `conversion: {strategy: None}`;
pool Service→exact URL plus dynamic-CA target label; admission target labels;
exact old→target-only injector arguments and exact Pod origin annotation;
the exact shoot injector rules; and the co-located ServiceMonitor's explicit
namespaceSelector→implicit own namespace. Seed CRB subjects must actually match
after applying the documented placement patch, never through comparison masking.
Exact chart-generated provenance values (`helm.sh/chart`, app version/managed-by)
and the additions origin are guarded separately; other metadata is compared.

Only after legacy comparison succeeds are the repaired fields reconstructed
in memory to compare the old historical hashes: remove the six exact labels,
restore the old rules/fixed subject and historical public CA, and omit only the
seven resources already checked against legacy. No CA certificate is stored in
new source/artifacts. Schema/version arrays, all remaining Pod fields, webhook
paths/policies, RBAC, network selectors and meaningful metadata remain checked.
Mutation tests reject removals of every identity, all seven schema changes,
target/URL/CA/SAN drift, broad RBAC and NetworkPolicy changes. Raw-file references,
wrong vendored hashes, extra CAPI resources and service/URL coexistence fail.

Three restored seed policies preserve same-namespace apiserver traffic TCP9443
and `name=kube-monitoring` namespace traffic TCP8082. Their selected apiservers
are egress-isolated subject to the union of policies; no selectors were broadened.
The manager ConfigMap, old leader-election ClusterRole/Binding and controller
metrics Service (8443→`https`, selector `control-plane=controller-manager`) are
preserved even if redundant. The old leader-election pair retains its legacy
`metadata.namespace: kube-system`; it does not change cluster-scoped RBAC scope.

Test prerequisites: Git (with both pinned legacy/historical commits available),
Helm, Kustomize, `yq`, and Python 3.12+ with PyYAML. Standalone render tests use
the real public provider base; for one verification run the same unchanged render
may be reused across checks after an actual online build.

```bash
cd system/kustomize/ipam-capi-remote-ddo
for test in tests/*_test.sh; do bash "$test" || exit 1; done
```

## Data and load-bearing identities

The two m-qa-de-200 pools remain out-of-band and are not rendered or adopted:

- `globalinclusterippool-mgmt-qa-de-200`, UID `83614ed7-f367-4bd0-acdd-4fbd4de76eec`, one allocation.
- `test`, UID `d7d99994-c27d-4116-835b-4d858069b7ea`.

Preserve them during cutover. `additions/shoot/pools.example.yaml` remains
unreferenced. Do not rename the controller Deployment/SA
`ipam-capi-controller-manager`, injector SA `ipam-capi-remote-webhook-injector`,
Service `ipam-capi-remote-webhook-service`, or shoot webhook configurations
`ipam-capi-remote-{mutating,validating}-webhook-configuration`. Shoot controller
SA lives in `kube-system`; DDO injects the seed object namespace at delivery.

## DDO CR contract

The overlay root is unchanged, but a downstream binding patch **is required**.
The CR resides under admin-k3s base defaults and the
qa-de-1/a-qa-de-200 instance in kube-secrets. The source URL includes `?ref=`;
`seedPath` and `shootPath` are relative to its `//path` root:

```yaml
source:
  kustomize:
    url: https://github.com/sapcc/helm-charts//system/kustomize/ipam-capi-remote-ddo?ref=<reviewed-commit>
    seedPath: seed
    shootPath: shoot
shootAccess:
  server: https://api.m-qa-de-200.cp.internal.a-qa-de-200.soil-garden.qa-de-1.cloud.sap
shootNamespace: kube-system
applyOrder: SeedFirst
```

The real seed CR namespace is `shoot--cp--m-qa-de-200`; shoot placement is
`kube-system`. DDO stamps object namespaces at delivery. The webhook-injector's
seed RBAC is a namespaced Role/RoleBinding whose same-namespace ServiceAccount
subject needs no explicit subject namespace, so no per-placement binding patch is
required. Instance transformation arrays replace defaults: retain **all**
host/kubeconfig and other required entries. No kube-secrets files are changed
here. Independent DDO integration remains a separate release gate.
