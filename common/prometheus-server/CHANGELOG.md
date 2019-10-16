## 3.0.0

* **[Breaking change]** Introduce `ingress.hosts=[]` for setting the hostnames. The first host will be used to generate the external URL for the Prometheus. Remainder is used as SANs.
  The values `ingress.host`, `ingress.hostNameOverride` are deprecated.
* Update Prometheus to `v2.13.0`.

## 2.2.3

* Fix naming of jobs for `kube-dns`, `cAdvisor`, `kubelet`, `kubernetes API server`, `node-exporter` service discoveries.

## 2.2.2

## 2.2.1

* Fix regex for pod and endpoint service discovery for metrics on an additional port.

## 2.2.0

* Add service discoveries for `kube-dns`, `cAdvisor`, `kubelet`, `kubernetes API server`, `node-exporter`. Disabled by default.

## 2.1.1

* Fix alerts for THanos compactor: `s/compact/compactor/g`.

## 2.1.0

* **[Breaking change]** If Thanos is being used the external labels `region`, `cluster`, `cluster_type` will be prefixed with `thanos_` to avoid the are being overwritten by the Thanos sidecar.   
  One has to ensure these labels are set during scrape via `relabel_config`. This is already if the default service discovery for endpoints, pods via ServiceMonitor, PodMonitor is being used.
* Added `alert_relabel_configs` to ensure `region`, `cluster`, `cluster_type` labels exist on alerts.
* Adds alert and playbook for out-of-order ingestion of metrics.
* The label `cluster_type` is no longer optional and pre-set to `controlplane`.

## 2.0.1

* Fix infinite redirect when accessing `/thanos` sub path.

## 2.0.0

* Resilience and fine-tuning for Thanos components. Prepare for upgrade to newer versions.
* Expose Thanos' Query components via ingress using subpath `/thanos`.

## 1.2.3

* Add alerts for Thanos sidecar, store, query, compactor and playbooks.

## 1.2.2

* Add alerts for Prometheus/Alertmanager issues.

## 1.2.1

* Fix playbook links.

## 1.2.0

* Bump Prometheus server to `v2.12.0`.
* Introduce [alerts for common Prometheus failures](./templates/alerts).

## 1.1.23

* Adds `region` and if set add `cluster_type`, `cluster` label to all metrics. 

## 1.1.22

* Configurable OpenstackSeed for Thanos integration. Extend [Thanos README](./templates/thanos/README.md).

## 1.1.21

* Configurable `affinity` and `nodeSelector` for Prometheus server instances.

## 1.1.20

* Extend clusterrole to for kubelet (`nodes/metrics`), cAdvisor (`nodes/metrics/cAdvisor`) metrics.
* Do not create serviceaccount with name `default` but generate the name in the format `prometheus-<name>` instead.

## 1.1.19

* Prometheus server to `v2.11.1`.

## 1.1.18

* [CI] Helm chart tests.

## 1.1.17

* Prometheus server to `v2.10.0`.

## 1.1.16

* Fix Service and Pod SD regex.

## 1.1.15

* Fix empty additionalScrapeConfigs by defaulting to `{}`.

## 1.1.14

* Set `honor_labels: true` for endpoint SD.

## 1.1.13

* Fix alertmanager configuration secret name.

## 1.1.12

* Re-add `ServiceMonitor.Spec.Selector` as required by k8s 1.10+.

## 1.1.11

* Cleanup PodMonitors.

## 1.1.10

* Fix metric port.

## 1.1.9

* Allow extending `prometheus.io/targets` annotations via `.Values.serviceDiscoveries.targetsOverride`.

## 1.1.8

* Bump Thanos image.

## 1.1.7

* Bump Prometheus to v2.9.2

## 1.1.6

* Bump Thanos image.

## v1.1.5

* Fix for incorrect thanos config name introduced in v1.1.4.

## v1.1.4

* Prefix Thanos components with `prometheus-<name>` and adjust labels to allow multiple Prometheis with Thanos instances per namespace.

## v1.1.3

* Fix setting Thanos image in chart.

## v1.1.2

* Fix OpenStack seed for Thanos.
* Use `sapcc/thanos:v0.4.0-e697626a` with support for cross domain scoping.

## v1.1.1

* Adds Thanos support.

## v1.1.0

* Changed defaults to `rbac.create=true`, `serviceAccount.create=true`.

## v1.0.20

* Support mounting additional secrets.

## v1.0.19

* Prefix all resources (confimaps,ingress, service, etc.) with `prometheus-<name>`. 

## v1.0.18

* Configurable client certificate authentication. Enabled by default.

## v1.0.17

* Fix service name.

## v1.0.16

* Configurable selector for persistent volume.

## v1.0.15

* Configurable global `.Values.scrapeInterval`.

## v1.0.14

* Allow setting complete hostname via `.Values.ingress.hostNameOverride`.

## v1.0.13

* Allow setting additional annotations on ingress.

## v1.0.12

* Fix missing base64 encoding of alertmanager configuration.

## v1.0.11

* Update to prom/prometheus:v2.9.1

## v1.0.10

* Add tolerations.

## v1.0.8

* Add out-of-the-box service discovery for endpoints, services.

## v1.0.7

* Add configurable security context.

## v1.0.6

* Add option to inject additional configmaps to a prometheus instance via `.Values.configMaps`.
* Add option to specify list of alertmanagers via `.Values.alertmanagers`.
