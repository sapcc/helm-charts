Prometheus Chart
----------------

This chart shall serve as a template to deploy your own Prometheus.  
It will set up:
- Prometheus server instance (with 2 sidecars: configmap, rules reload)
- Persistent volume claim (if configured; default off)
- Ingress (if configured; default off)
- RBAC resources (if configured; default off)

## Prerequisite

This chart relies on resources brought to you by the [Prometheus Operator](https://github.com/coreos/prometheus-operator).  
It may be installed using the [official helm chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

## Configuration

The following table provides an overview of configurable parameters of this chart and their defaults.  
See the [values.yaml](./values.yaml) for more details.

|       Parameter                        |           Description                                                                                                   |                         Default                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| `global.region`                        | The OpenStack region.                                                                                                   | `""`                                                |
| `global.domain`                        | The URL domain.                                                                                                         | `""`                                                |
| `global.clusterType`                   | Optional: The type of the cluster to which the Prometheus is deployed.                                                  | `""`                                                |
| `global.cluster`                       | Optional: The name of the cluster to which the Prometheus is deployed.                                                  | `$global.region`                                    |
| `image.repository`                     | Repository of the Prometheus image.                                                                                     | `prom/prometheus`                                   |
| `image.tag`                            | Tag of the Prometheus image.                                                                                            | `v2.8.0`                                            |
| `name`                                 | Unique name for this Prometheus instance. The name will be used to assign aggregation and alerting rules to Prometheus. | `""`                                                |
| `retentionTime`                        | Defines how long data is stored. Format: `[0-9]+(ms|s|m|h|d|w|y)`.                                                      | `7d`                                                |
| `additionalScrapeConfigs`              | List of Secrets containing the additional scrape configuration.                                                         | `[]`                                                |
| `ingress.enabled`                      | If enabled deploy an Ingress for this Prometheus.                                                                       | `false`                                             |
| `ingress.host`                         | Used to generate the external URL and ingress host in the form `<host>.<region>.<domain>`.                              | `""`                                                |
| `ingress.vice_president`               | Automate certificate management via vice-president (k8s operator).                                                      | `true`                                              |
| `ingress.disco`                        | Automate management of DNS provider via disco (k8s operator).                                                           | `true`                                              |
| `persistence.enabled`                  | If enabled a persistent volume is used to store the data. Else data is stored in memory.                                | `false`                                             |
| `persistence.name`                     | Name of the persistent volume claim.                                                                                    | `$name`                                             |
| `persistence.accessMode`               | Access mode for the persistent volume.                                                                                  | `ReadWriteOnce`                                     |
| `persistence.size`                     | The size of the persistent volume claim with unit.                                                                      | `300Gi`                                             |
| `logLevel`                             | The log level of the Prometheus server                                                                                  | `info`                                              |
| `resources.requests.cpu`               | Kubernetes resource requests for CPU.                                                                                   | `12`                                                |
| `resources.requests.memory`            | Kubernetes resource requests for memory.                                                                                | `40Gi`                                              |
| `rbac.create`                          | Create RBAC resources.                                                                                                  | `false`                                             |
| `serviceAccount.name`                  | Name of the service account to use for the Prometheus server.                                                           | `""`                                                |
| `thanos`                               | Thanos sidecar configuration.                                                                                           | `{}`                                                |
| `externalLabels`                       | The labels to add to any time series or alerts when communicating with any external system.                             | `{}`                                                |

## Providing addition scrape configurations

Additional scrape configuration is provided via a secret referenced by the `additionalScrapeConfigs.name` and `additionalScrapeConfigs.key` parameters.  
See the `prometheus.yaml` and `additional-scrape-config.yaml` in the [examples](./examples) folder.

## Aggregation and Alerting rules

Aggregation and alerting rules can be deployed independently of the Prometheus server instance using the `PrometheusRule` CRD.  
An example can be found [here](./examples/kubernetes-health.alerts.yaml).  
Rules are assigned to a Prometheus instance by setting labels on the PrometheusRule as shown below. See the `name` parameter in table above.
```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule

metadata:
  labels:
    prometheus: < name of the prometheus to which the rule should be assigned to >
  ...
```
