## 7.5.0 - 7.5.1

* Adding linkerd

## 7.4.16

* request ephemeral storage to avoid evicting due to minor usage

## 7.4.15

* Added failsafe to Prometheus kubernetes and kubernikus specific alerts with hint to thanos ruler.
* improved VPA alerts

## 7.4.14

* default value for shards
* vpa scope to Prometheus resource to ensure operator compatibility with scale subresource

## 7.4.9 - 7.4.10

* VPA mapping adjustment to set individual values 
* minReplicas set to 1

## 7.4.8

* VPA memory and cpu alerts added

## 7.4.7

* corrected VPA memory directive 

## 7.4.6

* bump to v2.47.2

## 7.4.5

* preparing VPA for rollout (make maxAllowed configurable)

## 7.4.4

* Soften out-of-order alert 

## 7.4.3

* Thanos sidecar to v0.31.0 to match Thanos environment 

## 7.4.2

* playbook link adjusted

## 7.4.1

* switch Ingress nginx-annotation

## 7.4.0

* updating Prometheus to v2.46.0

## 7.3.0

* Swift container userName and containerName now can be set explicitly

## 7.2.16

* If no `kube_` metrics available within the Prometheus, send `PrometheusMultiplePodScrape` alerts to specified Thanos Rule

## 7.2.15

* Removal of Prometheus limit warnings, as no limits are defined at all

## 7.2.14

* Refine PrometheusTargetSyncFailure alert

## 7.2.13

* Chart version labeled

## 7.2.12

* scrapeConfigSelector added to the Prometheus CR

## 7.2.11

* Defaulting ingressClassName to nginx to avoid picking up traefik 

## 7.2.10

* Improved RemoteWriteBehind alert

## 7.2.9

* adding thanos endpoint for internalIngress 

## 7.2.8

* Option to create unique swift containers

## 7.2.7

* Switch domain source to `.Values.global.tld`

## 7.2.6

* Add labels to metrics that originate from servicemonitors to identify a kubernikus kluster

## 7.2.5

* bump Prometheus to v2.43.0

## 7.2.2 - 7.2.4

* Enhance pod-sd to allow custom metric relabelings

## 7.2.0 - 7.2.1

* Updating Prometheus to 2.42.0
* removing networking.k8s.io/v1beta1 for ingresses (not used in the clusters anymore)

## 7.1.40 - 7.1.41

* HighAlert playbook link added
* HighAlert condition increased

## 7.1.39

* Thanos sidecar and Prometheus logLevel defaults to warn.

## 7.1.38

* Thanos alert duration trigger is less sensitive now

## 7.1.34 - 7.1.37

* SidecarDiscovey added

## 7.1.33

* Fixing vpa quotes

## 7.1.32

* Option to disable the object store in order to enable only the gRPC store API for the Thanos sidecar. 

## 7.1.31

* VerticalPodAutoscaler starts off initially

## 7.1.30

* VerticalPodAutoscaler for prometheus pod only

## 7.1.29

* `PrometheusHighAlertRate` notifications not for all configured alert managers

## 7.1.28

* Limitation to own `pod-sd` scrape job for `PrometheusMultiplePodScrapes` alert

## 7.1.26 - 7.1.27

 * Order of coalescence reverted (prometheus.name source defaults to `.Values.name`)

## 7.1.23 - 7.1.25

 * Revised Prometheus and Thanos sidecar alerts; added PodMonitor for Thanos sidecar. 

## 7.1.22

 * Forward PrometheusMultiple**ScrapeAlerts to the ccloud_support_group label, if present

## 7.1.21

 * Order of coalescence corrected

## 7.1.20

 * Option to set support_group for alerts

## 7.1.19

 * Update k8s apiserver metric names

## 7.1.17 - 7.1.18

* Dedicated thanos seed deployment to support various clusters. Seeds are going to be deployed in metal only

## 7.1.15 - 7.1.16

* remoteWrite alerting added

## 7.1.14

* remoteWrite CA added

## 7.1.12 - 7.1.13

 * configurable multipe scrapes alerts

## 7.1.11

* adding remoteWrite

## 7.1.1 - 7.1.9

* fix prometheus alerts; fix service label for ServiceMonitor

## 7.1.1 - 7.1.9

* Bug fixes in the new minor version

## 7.1.0

* Enabling the common chart to deploy multiple Prometheus. This can be done either via the list `names: []` or via a list of targets to create Prometheis `global.targets: []`. Existing configurations will not break as this chart is still able to create single Prometheus configured with `name:` only.

## 7.0.15

* changed service annotation on alerts

## 7.0.14

* fix node-exporter selector

## 7.0.14

* Add `container_oom_events_total` cadvisor metric by default

## 7.0.12

* Exclude `job=prometheus-vmware` from PrometheusMultipleTargetScrapes alert because this target is scraped with multiple jobs to the same target intentionally. Every scrape just replies a single metric.

## 7.0.11

* Add `metrics_path` label to pod and service SD targets

## 7.0.10

* Bump prometheus to v2.39.1

## 7.0.9

* removing Thanos prefix as it is only used in global Thanos Prometheis -> restoring region, cluster, cluster_type labels

## 7.0.6 - 7.0.8

* AlertWithMissingSupportGroupLabel alert added

## 7.0.5

* fix PrometheusMultipleTargetScrapes in global proms

## 7.0.4

* label fix for prometheus operator bump

## 7.0.2 - 7.0.3

* Move PrometheusMultiplePodScrapes to prometheus-kubernetes-rules chart

## 7.0.1

* Fix selector in service

## 7.0.0

* *Breaking change*: Global instances will not work, Thanos deployment files are removed.
* Enabled Thanos sidecar by default. Look at templates/thanos/README.md for instructions, swiftStorageConfig needs to be set
* Removed deployment charts for Query, Compactor, Store.
* Removed all thanos related alerts, leaving sidecar in place
* incorporated tier and service template of prometheus-kubernetes-rules to alerts, since it is used by ALL Prometheis

## 6.3.2

* Respect alert-service and alert-tier pod labels in PrometheusMultiplePodScrapes alert

## 6.3.1

* switch swift user for OpenstackSeed

## 6.3.0

* Bump Prometheus server to `v2.36.1`.

## 6.2.3

* Collect Prometheus metrics from pod/service ports named like `metrics-.*` in addition to from ports named `metrics`. This is intended to make the `prometheus.io/port` and `prometheus.io/port_1` annotations fully obsolete.

## 6.2.2

* Add dedicated alert for multiple scrapes from pod services discovery (PrometheusMultiplePodScrapes).

## 6.2.1

* Fix service discovery for endpoint/service by port name.

## 6.2.0

* Only set resource requests via VPA.

## 6.0.1

* Allow setting minimal resource requirements to be considered by VPA.

## 6.0.0

* The VPA update mode was set to `Initial` to enable metric-based adjustment of resource constraints on pod creation.

## 5.3.5

* Avoid double alerting for `PrometheusMultipleTargetScrapes` when `up` metric is being federated.

## 5.3.4

* Adds `/-/healthy` endpoint to internal ingress.

## 5.3.3

* Adds `/api` endpoint to internal Ingress.

## 5.3.2

* Optional additional internal ingress is limited to `/federate` and thanos paths. 

## 5.3.1

* Make ingress API version depend on k8s version.

## 5.3.0

* Allow separate configuration of internal ingress via values. 

## 5.2.0

* Use internal ingress with SSO authentication for federation.

## 5.1.0

* Update Prometheus to `v2.34.0`.

## 5.0.0

* Add OAUTH2 support on ingress level.
* Use ingress API version `networking.k8s.io/v1`.
* **Breaking change**: Helm values for ingress level authentication were moved one level down to `.Values.ingress.authentication.sso`

## 4.6.0

* Adds VerticalPodAutoscaler for Prometheus StatefulSet in recommendation mode

## 4.5.5

* [pod service SD] fix regex for disovering `(9102;.*;.*)|(.*;metrics;.*)|(\d+;.*;\d+)|(.*;.*;\d+)`

## 4.5.4

* [endpoint/service SD] Exclude set of metrics from being scrapped.
* [pod/service SD] Exclude set of metrics from being scrapped.

## 4.5.3

* [endpoint/service SD] Fix scraping of ports declared by the pod but not the service

## 4.5.2

* [cadvisor/kubelet SD] Exclude cadvisor/kubelet in PrometheusMultipleTargetScrapes as the instance is the same but the metric path is different. 

## 4.5.1

* [kube-dns SD] Label change: instance=address, node=kubernetes node name

## 4.5.0

* Bump Prometheus to `v2.32.1`.

## 4.4.7

* Added alert for duplicate scraping of targets.
* Fix double scraping of kube-dns.

## 4.4.0

* Update Prometheus to `v2.31.1`.

## 4.3.0

* Fix Thanos cross-domain authentication in config.
* Update Thanos to `v0.23.1`.

## 4.2.2

* Enables podMonitorSelector by default. Previously it was toggled by `.Values.serviceDiscoveries.pods.enabled` or `.Values.serviceDiscoveries.kubeDNS.enabled`

## 4.2.1

* Ensure kubelet and cAdvisor metrics have labels `pod`, `pod_name`, `container`, `container_name` present for compatibility reasons.   

## 4.2.0

* Upgrade Prometheus to `v2.28.1`.
* cAdvisor ServiceMonitor ready for Kubernetes `>=1.20`. Include probe metrics.
* Set default service discovery scrape interval to `30s`.
* API version of RBAC resources updated to `v1`.

## 4.1.0

* Upgrade Prometheus to `v2.27.0`.
* Upgrade Thanos components to `v0.20.1`.

## 4.0.1

* Change Thanos from dockerhub to keppel mirror.

## 4.0.0

* **[Breaking]** ChartVersion is now v2.
* Remove `vice-president` annotation from Ingress.
* Bump Prometheus to `v2.23.0`.
* Switch from sapcc fork to upstream and upgrade Thanos components to `v0.17.1`. 
This includes the Thanos sidecar to the Prometheus server, resolving the memory leak.


## 3.7.2

* Fix deprecated apiVersions for Thanos components, Prometheus ingress.

## 3.6.2

* Added annotation triggering certificate automation: `kubernetes.io/tls-acme: "true"`.

## 3.5.1

* Allow scraping pods via https. Use `prometheus.io/scheme: "https"` annotation.

## 3.5.0

* Update prometheus-server to `v2.19.0`.

## 3.4.2

* Ensure mandatory labels are present on alerts.

## 3.4.1

* Fix `resource.requests.cpu`: It shall be a string.

## 3.4.0

* Bump Prometheus to `v2.17.2`.
* Update `Prometheus.Spec.{rule|podMonitor|serviceMonitor}NamespaceSelector` to consider every namespace. (Behaviour didn't change but configuration in Prometheus CRD from `any` to `{}`)

## 3.3.6

* Standardize labels: Introduce labels `container`, `pod` in cAdvisor metrics.
  These shall be used instead of `container_name`, `pod_name` to be consistent with kube-state-metrics, kubelet and avoid further `label_replace` in PromQL queries.
  **Note**: The label `container_name`, `pod_name` might be dropped from cAdvisor metrics in the next major release.

## 3.3.5

* Standardize labels: Ensure the `node` label (node name) is present on cAdvisor, kubelet metrics. 

## 3.3.4

* Fix node label for kubelet job.
* Upgrade Prometheus to `v2.15.2`.

## 3.3.3

* Unify labels (instance vs node).

## 3.3.2

* Allow configuring Alertmanagers which require authentication. The relevant `.Values.alertmanagers` section was exploded to:
  ```yaml
  # Alertmanager configuration.
  alertmanagers:
    # Configuration if the Alertmanager has client certificate authentication enabled.
    authentication:
      enabled: false
      # The certificate used for authentication with the Alertmanager..
      ssoCert: 
      # The key used for authentication with the Alertmanager.
      ssoKey:
  
    # List of Alertmanagers (AM) to send alerts to.
    # If multiple AMs are used in an HA setup, alerts must be send to every AM.
    hosts: []
    # - alertmanager1.tld
    # - alertmanager2.tld
  ```
* Fixed double scraping for service/endpoint service discovery when using `prometheus.io/port` annotation. 
  A service has to declare the port(s) on which they expose metrics on in their spec. The service gets dropped otherwise.
  Per default Prometheus tries to get metrics from service ports with the name `metrics`. 

## 3.1.1

* Fix SD config for `prometheus.io/port_1` as well.

## 3.1.0

* Potential **Breaking change** if the out-of-the-box pod service discovery is being used.
  To avoid double scraping of metrics from pods with multiple containers, the containers have to explicitly declare the port(s) on which they expose metrics on in their spec.
  They will no get scraped otherwise.
  Per default Prometheus tries to get metrics from ports with number `9102` or name `metrics`. 
* Bump Prometheus to `v2.14.0`.
* Update Thanos components to `v0.8.1`.  

## 3.0.5

* Allow setting additional annotations on the service via `.Values.service.annotations`.

## 3.0.4

* Fix `PrometheusNotIngestingSamples` alert.

## 3.0.3

* Fix externalURL if `.Values.ingress.hostsFQDN` are set.

## 3.0.2

* Allow setting fully qualified hostnames via `.Values.ingress.hostsFQDN`. Mutually exclusive with `.Values.ingress.hosts`.

## 3.0.1

* Alert if Prometheus is not ingesting samples.

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
