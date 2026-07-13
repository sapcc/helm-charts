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
