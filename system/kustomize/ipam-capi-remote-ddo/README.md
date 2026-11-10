# ipam-capi-remote-ddo

A **DDO source.kustomize operand**, not a Helm chart. DDO renders `seed/` and
`shoot/` independently and server-side-applies each to its respective cluster.

## Release gate

**Do not activate this candidate based only on these static tests.** Deploy a
DDO release supporting safely acquired, SHA-pinned remote sources —
both Git directory bases and individual raw file URLs — and
`spec.source.kustomize`, plus an admin chart that renders that source type.
All seven CRDs are fetched remotely: the four provider pool CRDs through a
pinned Git directory base, the three core CRDs through SHA-pinned raw file
URLs. Nothing is vendored. Do not relax DDO preflight. An online CLI build is
not evidence of production cache/offline semantics.

Before cutover: independently verify DDO integration, the required seed binding
transformation below, current shoot credentials, initial CA stamping and rotation,
and shoot-apiserver reachability/TLS to the legacy short webhook URL. Preserve
the out-of-band pools and coordinate old/new injector ownership. Runtime target
mode patches CA only; it does not create targets or repair their URLs. Publish
the required operator/chart releases and review the complete downstream CR
transformation list before activating kube-secrets PR #5683 / migration PR #13218.
No live connectivity, upgrade or rotation safety is established by this suite.

## Structural mode contract

There is no `mode` value. `seed/` composes only `../additions/seed`;
`shoot/` composes `../additions/shoot`, its remote CRD sources, RBAC,
and webhook configurations. SAP-added resources carry:

```yaml
dual-deployment-operator.cc.sap/origin: additions
```

## Layout

```text
system/kustomize/ipam-capi-remote-ddo/
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
    core-crds/                         # three SHA-pinned raw CRD URLs + provenance README
      kustomization.yaml               # remote resources + explicit conversion default
    patches/conversion-*.yaml           # four SAP pool conversion shims
    rbac.yaml
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
| kubernetes-sigs/cluster-api | v1.14.2 | `5f7d58c9ad647f31bd342bf8de33092c27f7fc38` | Exactly Cluster, IPAddress, IPAddressClaim via SHA-pinned raw file URLs in `shoot/core-crds/` |

The provider pool CRDs use a Git directory base. The three core CRDs are each
referenced individually as SHA-pinned raw file URLs — CAPI's
`core/config/crd/bases` directory bundles thirteen CRDs and this operand owns
only three, so the whole directory must never be imported. See
[core source provenance](shoot/core-crds/README.md) for the exact three URLs.
Every remote ref MUST be a full 40-character commit SHA, never a mutable tag.

The four pool CRD patches are **label-only** strategic-merge patches: each adds
only the `dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote`
label. The conversion block — `strategy: Webhook`,
`clientConfig.service{name: webhook-service, namespace: system, path: /convert}`,
and `conversionReviewVersions: [v1]` — is **inherited from the upstream
`//config/crd` base** and is not repeated in the SAP patches. The final
conversion URL (`https://ipam-capi-remote-webhook-service:443/convert`) is
**computed at deploy time** by the DDO `rewriteWebhookURL` transform
(`urlPrefix: https://ipam-capi-remote-webhook-service:443`); it does not exist
as a static value in this repository. The same `rewriteWebhookURL` transform
also produces the admission MWC/VWC URLs. The three core CRDs omit conversion;
a small patch keeps the explicit `{strategy: None}` default. No upstream schema
is changed. All four pools and both admission configurations carry
`dual-deployment-operator.cc.sap/webhook-injector: ipam-capi-remote`, matching
exactly one injector `--target-label` argument. Core CRDs are not targeted.
The injector owns CA dynamically; DDO must continue stripping only the CA leaf
before SSA. `--cert-sans=ipam-capi-remote-webhook-service` preserves the legacy
topology; it does not prove that the endpoint is reachable.

Pool CRDs retain controller-gen v0.17.2 and the empty
`clusterctl.cluster.x-k8s.io/move-hierarchy` label. Core CRDs retain v0.21.0 and
no move-hierarchy label. Provider and cert-manager injection metadata are absent.

### Accepted maximize-upstream scope

This candidate fetches all seven CRDs remotely (four pool CRDs via a pinned Git
directory base, three core CRDs via SHA-pinned raw file URLs). The existing `shoot/rbac.yaml`
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
- Injector: `ghcr.io/sap-cloud-infrastructure/webhook-injector:sha-bb2f978ca889e1da27c33faba3fe78b1b1dfd221`
  → `keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector` with the same tag.

The shared seed kubeconfig and manager host retain neutral placeholders.
Per-cluster kube-secrets CR transformations supply the actual kubeconfig server
and `KUBERNETES_SERVICE_HOST`. The CR must also carry a `rewriteWebhookURL`
transform with `urlPrefix: https://ipam-capi-remote-webhook-service:443`, which
produces both the admission MWC/VWC URLs and the four pool-CRD conversion URLs
at deploy time. All six target labels are already in source.
`shootAccess.server` configures DDO's client, not the operand's mounted kubeconfig.

## Maintenance and fidelity

1. Resolve a new upstream release tag to its **commit**, not its tag object.
2. Review upstream schema, served/storage versions, conversion, RBAC and manager
   changes against the current pins. Update the Git directory and raw-file commit pins coherently.
3. Review conversion patches and any necessary local RBAC/Deployment changes.
   Image tags are maintained separately via `images:`.
4. Run the complete suite. Intentional schema changes require explicit baseline
   review; never regenerate fingerprints automatically to hide a mismatch.
5. Review the source-pin and fingerprint diff together before deployment.

`tests/crd-baseline.json` is a guarded render fingerprint, regenerated deliberately
for this reorganization (its file hash is pinned in the contract test). Tests first
render the actual Helm chart at `97d52c25ae067c00fd5f5b3e7a66771fdcbc10db`, unwrap
ManagedResources and the webhook ConfigMap, and require its exact identities minus
the deliberately dropped objects: **13 seed / 21 shoot**. The legacy chart's dead
webhook-injector seed ClusterRole/ClusterRoleBinding and its two redundant shoot
leader-election ClusterRole/ClusterRoleBinding pairs are intentionally not delivered
and are filtered from the oracle comparison. Independent nonsecret input values pin
the same images/security settings as the candidate. No live capture is needed; those
Git commits must exist locally.

The only guarded migration deltas are: core `conversion: {strategy: None}`;
pool deploy-time URL via `rewriteWebhookURL` plus dynamic-CA target label; admission target labels;
exact old→target-only injector arguments and exact Pod origin annotation;
the exact shoot injector rules; and the co-located ServiceMonitor's explicit
namespaceSelector→implicit own namespace. The webhook-injector seed RBAC is a
namespaced Role/RoleBinding whose same-namespace SA subject needs no explicit
subject namespace, so there is no seed ClusterRoleBinding and no placement patch.
Exact chart-generated provenance values (`helm.sh/chart`, app version/managed-by)
and the additions origin are guarded separately; other metadata is compared.

Only after oracle comparison succeeds are the repaired fields reconstructed
in memory to compare the historical fingerprints: remove the six exact labels,
restore the old rules and historical public CA, and omit only the restored
resources already checked against the oracle. No CA certificate is stored in
new source/artifacts. Schema/version arrays, all remaining Pod fields, webhook
paths/policies, RBAC, network selectors and meaningful metadata remain checked.
Mutation tests reject removals of every identity, all seven schema changes,
target/URL/CA/SAN drift, broad RBAC and NetworkPolicy changes. Mutable (non-SHA)
remote refs, the full CAPI CRD directory, extra CAPI resources and service/URL
coexistence fail.

Three restored seed policies preserve same-namespace apiserver traffic TCP9443
and `name=kube-monitoring` namespace traffic TCP8082. Their selected apiservers
are egress-isolated subject to the union of policies; no selectors were broadened.
The manager ConfigMap and controller metrics Service (8443→`https`, selector
`control-plane=controller-manager`) are restored. The redundant leader-election
RBAC is intentionally dropped: the manager runs `--leader-elect=false`, so it
elects nothing, and the legacy ClusterRole promotion was only a workaround for the
Gardener ManagedResource namespace limit that DDO's direct apply removes.

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
