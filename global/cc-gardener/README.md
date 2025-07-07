# Install

- setup operator CRDs
```sh
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.117.5/charts/gardener/operator/templates/crd-extensions.yaml
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.117.5/charts/gardener/operator/templates/crd-gardens.yaml
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
- read [the changelog](https://github.com/gardener/gardener/releases)
- update crd links in readme
    - apply CRDs when there are changes
- change `version`, `appVersion` and `version` of operator in `Chart.yaml`
- change `.operator.image.tag` in `values.yaml`
- `helm dep up`
- mirror gardenlet helm chart
    - `helm pull oci://keppel.eu-de-1.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/gardener-project/releases/charts/gardener/gardenlet:v1.117.5`
