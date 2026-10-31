# ipam-capi-remote-ddo

A **DDO source.kustomize operand**, not a Helm chart. DDO renders `seed/` and
`shoot/` independently and server-side-applies each to its respective cluster.

## Release gate

**Do not activate this remote-source variant until safe fetching is released and
deployed.** [DDO issue #58](https://github.com/SAP-cloud-infrastructure/dual-deployment-operator/issues/58)
must cover both Git directory bases and plain-HTTP file resources. Required
evidence: cold-cache fetch succeeds, warm-cache rendering works with outbound
network blocked, an unavailable uncached source fails closed, and repeated
renders are deterministic. A local Kustomize CLI build does not prove any of
these DDO guarantees. Fresh CLI builds require network; offline DDO builds
require a populated cache. This variant is folded into draft migration PR
#13218; it is not a separate follow-up. The admin DDO chart must also support
rendering `spec.source.kustomize` (its current 0.1.8 CR template renders Helm
sources only). Release/publish that delivery support before merging the related
kube-secrets CR PR #5683. Both PRs remain blocked until these prerequisites hold.

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
  additions/shoot/
    kustomization.yaml
    pools.example.yaml                 # unreferenced example
  seed/kustomization.yaml
  shoot/
    kustomization.yaml                 # provider Git base + core-crds + local RBAC/webhooks
    core-crds/kustomization.yaml        # three HTTP files + explicit conversion default
    patches/conversion-*.yaml           # four SAP pool conversion shims
    rbac.yaml
    webhooks.yaml
  tests/
    crd-baseline.json                   # compact immutable render fingerprints
    crd_parity.py
    *_test.sh
```

## Upstream sources and SAP deltas

| Origin | Release | Resolved commit | Delivered objects |
| --- | --- | --- | --- |
| kubernetes-sigs/cluster-api-ipam-provider-in-cluster | v1.1.1 | `7933583138cf1b5b16b6a1dd82a804729f83afab` | Four pool CRDs through `//config/crd?ref=<SHA>` |
| kubernetes-sigs/cluster-api | v1.14.2 | `5f7d58c9ad647f31bd342bf8de33092c27f7fc38` | Cluster, IPAddress, IPAddressClaim through `raw.githubusercontent.com/<owner>/<repo>/<SHA>/core/config/crd/bases/<file>` |

Git directory bases require a kustomization directory; per-file Git references
do not work. The HTTP file loader fetches individual core CRDs with the commit
SHA in the URL path. Do not import CAPI's entire CRD directory: it introduces ten
additional CRDs this operand does not own.

The four pool patches preserve URL-only conversion to
`https://ipam-capi-remote-webhook-service:443/convert`, the captured CA bytes,
and review version `v1`. `clientConfig.service: null` explicitly removes the
upstream service reference. The three core sources omit `conversion`; a small
patch restores the existing explicit `{strategy: None}` default. No upstream
schema is copied or changed. Keeping the captured CA is a parity decision,
**not** a claim that every cluster shares a CA because its issuer CN matches.

Pool CRDs retain controller-gen v0.17.2 and the empty
`clusterctl.cluster.x-k8s.io/move-hierarchy` label. Core CRDs retain v0.21.0 and
no move-hierarchy label. Provider and cert-manager injection metadata are absent.

### Accepted maximize-upstream scope

This refactor fetches all seven CRDs. The existing normalized `shoot/rbac.yaml`
stays local: importing the full upstream RBAC base adds unwanted objects and
namespaced leader-election roles instead of the existing remote cluster-scoped
variant. It also contains SAP metal cross-operator bindings and webhook-injector
permissions. The URL-based webhook configurations, seed remote-controller
wiring, and pool example remain local and unchanged. This is the accepted
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
and `KUBERNETES_SERVICE_HOST`, plus injector target labels on both shoot webhook
configurations. `shootAccess.server` configures DDO's client, not the operand's
mounted kubeconfig.

## Maintenance and fidelity

1. Resolve a new upstream release tag to its **commit**, not its tag object.
2. Review upstream schema, served/storage versions, conversion, RBAC and manager
   changes against the current pins. Bump Git and HTTP pins coherently.
3. Review conversion patches and any necessary local RBAC/Deployment changes.
   Image tags are maintained separately via `images:`.
4. Run the complete suite. Intentional schema changes require explicit baseline
   review; never regenerate fingerprints automatically to hide a mismatch.
5. Review the source-pin and fingerprint diff together before deployment.

`tests/crd-baseline.json` records the pre-refactor Git commit, upstream pins, and
SHA-256 fingerprints per normalized object identity for both renders. The
canonicalization ignores mapping/document order and only the existing
server-populated metadata/status and Gardener/Helm delivery artifacts; it does
not ignore schema arrays, meaningful metadata, or CA bytes. It is a compact
historical reference, not a second copied CRD bundle.

`crd_diff_test.sh` **always** checks this tracked baseline, all seven names,
split stamps, labels and conversion wiring. Missing baseline fails; no
disposable live-capture directory is required. `crd_parity_test.sh` proves that
schema, inventory, CA and baseline mutations fail. `remote_sources_test.sh`
checks exact approved references and rejects mutable pins, extra CAPI sources,
missing patches and service/URL coexistence. The existing render, RBAC, seed,
webhook and no-pool gates still run independently.

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

The overlay root is unchanged; no kube-secrets or cutover update is required by
this sourcing refactor. The CR resides under admin-k3s base defaults and the
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
