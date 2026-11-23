# Install

- setup operator CRDs
```sh
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.144.2/charts/gardener/operator/files/crd-extensions.yaml
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.144.2/charts/gardener/operator/files/crd-gardens.yaml
k label crd gardens.operator.gardener.cloud extensions.operator.gardener.cloud app.kubernetes.io/managed-by=Helm
k annotate crd gardens.operator.gardener.cloud extensions.operator.gardener.cloud meta.helm.sh/release-name=cc-gardener meta.helm.sh/release-namespace=garden
```
- install with all switches set to false
    - "empty" upgrade in case install fails with webhook error
- wait for garden to become ready
    - may take 10 minutes
- upgrade enable managedresources
- upgrade with proper secrets-injector ca (`k get secret ca-bundle-***** -o yaml`)
- upgrade enable openstack extension
- upgrade enable gardenlet
    - add additional seeds to `.gardenlet.additionalSeedRegions`

# Upgrade

The `cc-gardener` chart is upgraded based on two inputs from the umbrella chart that includes it as a subchart:

1. **Operator subchart version** — defined in the umbrella chart's `Chart.yaml`.
2. **Generated `imageVectorOverrides`** — defined in the umbrella chart's `values.yaml`.

# Image digest regression tests

From the repository root, with Helm, Python 3 and yq v4 available:

```sh
helm dependency build global/cc-gardener
python3 global/cc-gardener/ci/test-image-digests.py
```

From this chart directory, run `helm dependency build .` and
`python3 ci/test-image-digests.py`. Dependencies use the existing lock file and
internal OCI registry; fetched archives must not be committed.

The tests render the real chart and decode the ManagedResource Secrets containing
Gardenlets. They also render the original chart at commit `04f4dbf7` using the same
dependencies, comparing ordinary, legacy digest-only and explicit-override output.
The ordinary secrets-injector separator fix is the only allowed ordinary change.
Use `--baseline-ref <commit>` to select a different original revision.
