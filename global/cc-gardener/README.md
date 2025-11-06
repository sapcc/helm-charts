# Install

- setup operator CRDs
```sh
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.128.7/charts/gardener/operator/templates/crd-extensions.yaml
k apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.128.7/charts/gardener/operator/templates/crd-gardens.yaml
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

# Upgrade Runtime Cluster Seeds
- exluding any cluster where Gardener Operator is running
- Fetch current values and output them to file
    `› helm get values gardenlet > gardenlet-values.yaml`
- Update image tag in `gardenlet-values.yaml`
    ```shell
    image:
      pullPolicy: IfNotPresent
      repository: europe-docker.pkg.dev/gardener-project/releases/gardener/gardenlet
      tag: v1.128.7  <<<
    ```
- Helm diff
    `› helm diff upgrade gardenlet oci://keppel.eu-de-1.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/gardener-project/releases/charts/gardener/gardenlet --version v1.128.7 -f gardenlet-values.yaml`
- Helm upgrade
    `› helm upgrade gardenlet oci://keppel.eu-de-1.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/gardener-project/releases/charts/gardener/gardenlet --version v1.128.7 -f gardenlet-values.yaml`

# Outdated
- mirror gardenlet helm chart (is now handled by [garden-pcr](https://ci1.eu-de-2.cloud.sap/teams/services/pipelines/garden-pcr))
- manual pull:
    - `helm pull oci://keppel.eu-de-1.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/gardener-project/releases/charts/gardener/gardenlet --version v1.128.7`

# Verify
- Check pods in the `garden` namespace on the seed cluster. `deployment/gardenlet` should have updated.
- Check `garden` resource in the on the seed cluster. It should have a new Gardener version.
- Check `gardenlet` resource in the on the garden cluster.
- Check `seed` resource in the on the garden cluster.
