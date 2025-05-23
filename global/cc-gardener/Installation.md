# Gardener installation on a new Runtime cluster (for Gardener 113.3)

For newer version of Gardener adapt version.

* Preparations:

```bash
alias uh='u8s helm --'
alias uk='u8s kubectl --'
alias ukg='uk get'
```

1. Install CRDs and apply annotations:

```bash
uk apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.113.3/charts/gardener/operator/templates/crd-extensions.yaml
uk apply -f https://raw.githubusercontent.com/gardener/gardener/refs/tags/v1.113.3/charts/gardener/operator/templates/crd-gardens.yaml
uk label crd gardens.operator.gardener.cloud extensions.operator.gardener.cloud app.kubernetes.io/managed-by=Helm
uk annotate crd gardens.operator.gardener.cloud extensions.operator.gardener.cloud meta.helm.sh/release-name=cc-gardener meta.helm.sh/release-namespace=garden
```

2. Install Gardener operator manual with `u8s` and Helm

Checkout `cc-gardener` commit version you want to install.

2.1. Copy custom values for the installation from already setup cluster that is maintained with the cc-gardener pipeline, e.g. `a-qa-de-200`:

* Create `custom-values.yaml` file from [this as reference values](https://github.wdf.sap.corp/cc/kube-secrets/blob/master/values/helm/admin-k3s/qa-de-1/a-qa-de-200/cc-gardener.yaml)

2.2. Change values as follows:

* `managedresources` to `false`
* All `enabled` properties to `false`
* `gardener` section changes:

1. Find external IP (look for `loadBalancerIP`) from Istio Ingressgateway LoadBalancer service, or if its still missing from the nginx LB (e.g. `kube-system/ingress-nginx-rt-qa-de-1-controller`):

```bash
[rt-qa-de-1|virtual-garden-istio-ingress]
~/repos/sapcc/helm-charts/global/cc-gardener remotes/origin/ccm~4*
❯ ukg service istio-ingressgateway -oyaml
```

2. Adapt `region` value for the new cluster.
3. Change bucket name, e.g. `cc-etcd-backup-virtual-garden-rt-qa-de-1`
4. Adapt the zones (check how many we use from nodes).
5. Networking changes for the runtime clusters:

* From `KubeadmControlPlane` on the admin cluster, CIDR ranges for `pods` and `services`:

```bash
[a-qa-de-1|capi-runtime]
~/repos/sapcc/helm-charts/global/cc-gardener master* ⇣
❯ ukg KubeadmControlPlane -o yaml kcp-rt-qa-de-1 | grep -C 10 networking
```

* Example:

```yaml
networking:
  dnsDomain: cluster.local
  podSubnet: 100.66.0.0/16
  serviceSubnet: 100.74.0.0/16
```

* Nodes CIDR from `GlobalInclusterIPPool`:

```bash
[a-qa-de-1|capi-runtime]
~/repos/sapcc/helm-charts/global/cc-gardener master* ⇣
❯ uk get globalinclusterippool
NAME                               ADDRESSES             TOTAL   FREE   USED
globalinclusterippool-rt-qa-de-1   ["10.245.234.0/26"]   30      22     8
```

* Adapt `custom-values.yaml`, e.g.:

```yaml
garden:
  runtimeCluster:
    networking:
      nodes: ["10.245.234.0/26"]
      pods: ["100.66.0.0/16"]
      services: ["100.74.0.0/16"]
```

* Networking for `virtualCluster`:

```yaml
networking:
  services: ["100.75.0.0/16"]
```

6. Add at the beginning of `custom-values.yaml`, some additional properties:

```yaml
global:
  registry: keppel.eu-de-1.cloud.sap/ccloud
  cluster: rt-qa-de-1
  region: qa-de-1
```

7. Create AWS S3 bucket `cc-etcd-backup-virtual-garden-rt-qa-de-1` (ask for permissions or ping @Dmitri), copy bucket policy from previous S3 buckets

> [!NOTE]
> This step may not be needed as of Gardener 1.114.3 (needs to be double checked)

2.3. Helm install:

```bash
uh install cc-gardener . -f custom-values.yaml --create-namespace -n garden

NAME: cc-gardener
LAST DEPLOYED: Wed May 21 10:29:34 2025
NAMESPACE: garden
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

* You may get:

```bash
Error: INSTALLATION FAILED: failed to create resource: Internal error occurred: failed calling webhook "defaulting.operator.gardener.cloud": failed to call webhook: Post "https://gardener-operator.garden.svc:443/webhooks/default-operator-gardener-cloud-v1alpha1-garden?timeout=10s": dial tcp 100.74.142.27:443: connect: connection refused
```

* Ignore and run `upgrade` with:

```bash
uh upgrade cc-gardener . -f custom-values.yaml --create-namespace -n garden
```

> [!NOTE]
> If scheduling of monitoring pods fail (alertmanager / prometheus) you can scale it down temporarily but you need to disable managedresource reconciliation with following annotation:

```yaml
annotations:
    resources.gardener.cloud/ignore: true
```

* See https://gardener.cloud/docs/gardener/concepts/resource-manager/#preventing-reconciliations

> [!NOTE]
> Do not forget to include the cluster in `Greenhouse` controlplane list for the `kube-monitoring` `PluginPreset` [in here](https://github.wdf.sap.corp/cc/secrets/blob/2a4c83c1c0dd364aec096bb6a51d03054b2b3905/eu-de-1/values/greenhouse-p-eu-de-1-ccloud.yaml#L316-L320)

2.4. Enable `managedresources` in values.yaml:

```yaml
garden:
  managedresources: true
```

and `upgrade` again.

2.5. Update `secrets-injector` CA.

* Get CA bunble from:

```bash
[rt-qa-de-1|garden]
~/repos/sapcc/helm-charts/global/cc-gardener remotes/origin/ccm~4*
❯ uk get secret ca-bundle-69742143 -oyaml
apiVersion: v1
data:
  bundle.crt: ...
```

and `upgrade` again.

2.6. Enable `openstack` extension:

```yaml
extensions:
  openstack:
    enabled: true
```

update zones if needed and `upgrade` again.

2.7. Enable `gardenlet`:

```yaml
gardenlet:
  enabled: true
```

and `upgrade` again.

2.8. Add the new g-cluster to registry:

* Use previous kubeconfig and adapt naming and api-server url from:
https://dashboard.eu-de-2.cloud.sap/ccadmin/master/object-storage/swift/containers/kubectl-registry-provider/objects

* Use CA from:

```bash
[rt-qa-de-1|garden]
~/repos/sapcc/helm-charts/global/cc-gardener remotes/origin/ccm~4*
❯ ukg secret ca-bundle-69742143 -oyaml
apiVersion: v1
data:
  bundle.crt:...
```

* and API server host from:

```bash
[rt-qa-de-1|garden]
~/repos/sapcc/helm-charts/global/cc-gardener remotes/origin/ccm~4*
❯ ukg virtualservice
NAME                            GATEWAYS                            HOSTS                                                                                                        AGE
nginx-ingress-controller-0      ["nginx-ingress-controller"]        ["*.runtime-garden.rt-qa-de-1.qa-de-1.cloud.sap"]                                                            27h
virtual-garden-kube-apiserver   ["virtual-garden-kube-apiserver"]   ["api.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap","gardener.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap"]   27h
```

* Upload new kubeconfig and trigger registry refresh (check logs for errors):
https://ci1.eu-de-2.cloud.sap/teams/services/pipelines/kubectl-sync/jobs/registry-refresh/builds/23116

2.9. Add new pipeline for the cluster:

* Copy `custom-values.yaml` as follows:

```bash
~/repos/cc/kube-secrets master
❯ git status
On branch master
Your branch is up to date with 'origin/master'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	values/helm/runtime/qa-de-1/rt-qa-de-1/cc-gardener.yaml
```

* Remove global settings from the file
* Update `cc-gardener-runtime` pipeline with new cluster in here `kube-secrets` (`/pipelines/cc-gardener-runtime`)
* Check if pipeline succeeds

3.0. Garden resource should looks like this:

```bash
[rt-qa-de-1|garden]
~/repos/cc/secrets add-controlplane-operations-plugin-catalog ⇣
❯ ukg garden
NAME     K8S VERSION   GARDENER VERSION   LAST OPERATION   RUNTIME   VIRTUAL   API SERVER   OBSERVABILITY   AGE
garden   1.30.5        v1.113.3           Succeeded        True      True      True         True            2d4h
```
