# Install

- setup operator CRDs
```sh
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.110.1/charts/gardener/operator/templates/crd-extensions.yaml
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.110.1/charts/gardener/operator/templates/crd-gardens.yaml
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

# Upgrade
- read [the changelog](https://github.com/gardener/gardener/releases)
- change `appVersion`, `version` and `version` of operator in `Chart.yaml`
- change `.operator.image.tag` in `values.yaml`
- `helm dep up`
