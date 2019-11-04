Prometheus Alertmanager Chart
-----------------------------

This chart shall serve as a template to deploy an Prometheus Alertmanager.  
It will set up:
- Prometheus Alertmanager instance with configmap reload sidecar
- Persistent volume claim (store Silences)
- Ingress to manage external access for the Alertmanager instance. (default off)

## Prerequisite

This chart relies on resources brought to you by the [Prometheus Operator](https://github.com/coreos/prometheus-operator).  
It may be installed using the [official helm chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

## Providing the Alertmanager configuration

The Alertmanager's configuration can be provided via `.Values.config`.
If helm templating is used in `.Values.config`, set `.Values.tplConfig` to `true`.

Alternatively, and existing Secret named `alertmanager-$name` can be used to provide the configuration using the key `alertmanager.yaml`. 
See the [example](./examples)

## Notification templates

[Notification templates](https://prometheus.io/docs/alerting/notification_examples) for Slack and Pagerduty are provided in the [notification-templates folder](./notification-templates).

**NOTE:** To use the notification templates the alertmanager configuration must include:
```yaml
templates:
  - /notification-templates/*.tmpl
```

## Chart configuration

The following table provides an overview of configurable parameters of this chart and their defaults.  
See the [values.yaml](./values.yaml) for more details.  

**TLDR:** Set the `name`, `global.region`, `global.domain` parameters and get started where `name` has to be a unique (per namespace) identifier for your Alertmanager.

|       Parameter                        |           Description                                                                                                   |                         Default                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| `global.region`                        | The OpenStack region.                                                                                                   | `""`                                                |
| `global.domain`                        | The URL domain.                                                                                                         | `""`                                                |
| `image.repository`                     | Repository of the Prometheus Alertmanager image.                                                                        | `prom/alertmanager`                                 |
| `image.tag`                            | Tag of the Prometheus Alertmanager image.                                                                               | `v0.19.0`                                           |
| `name`                                 | Unique name for this Prometheus Alertmanager instance.                                                                  | `""`                                                |
| `retention`                            | Defines how long data is stored. Format: `[0-9]+(ms|s|m|h)`.                                                            | `168h`                                              |
| `config`                               | The alertmanagers configuration.                                                                                        | `{}`                                                |
| `tplConfig`                            | Pass Alertmanager configuration through Helm templating.                                                                | `false`                                             |
| `useExistingSecret`                    | Pass the Alertmanager configuration through Helm templating.                                                            | `false`                                             |
| `templateFiles`                        | Defines how long data is stored. Format: `[0-9]+(ms|s|m|h|d|w|y)`.                                                      | `{}`                                                |
| `configmaps`                           | List of configmaps in the same namespace as the Alertmanager that should be mounted to `/etc/alertmanager/configmaps`.  | `[]`                                                |
| `secrets`                              | List of secrets in the same namespace as the Alertmanager that should be mounted to `/etc/prometheus/secrets`.          | `[]`                                                |
| `ingress.enabled`                      | If enabled deploy an Ingress for this Prometheus.                                                                       | `false`                                             |
| `ingress.host`                         | Used to generate the external URL and ingress host in the form `<host>.<region>.<domain>`.                              | `""`                                                |
| `ingress.hostNameOverride`             | Used to set the complete hostname and skip above generation.                                                            | `""`                                                |
| `ingress.vice_president`               | Automate certificate management via vice-president (k8s operator).                                                      | `true`                                              |
| `ingress.disco`                        | Automate management of DNS provider via disco (k8s operator).                                                           | `true`                                              |
| `ingress.annotations`                  | Additional annotations for ingress.                                                                                     | `{}`                                                |
| `ingress.authentication`               | Ingress client certificate authentication. See values for details.                                                      | `{}`                                                |
| `persistence.enabled`                  | If enabled a persistent volume is used to store the data. Else data is stored in memory.                                | `false`                                             |
| `persistence.name`                     | Name of the persistent volume claim.                                                                                    | `$name`                                             |
| `persistence.accessMode`               | Access mode for the persistent volume.                                                                                  | `ReadWriteOnce`                                     |
| `persistence.size`                     | The size of the persistent volume claim with unit.                                                                      | `10Gi`                                              |
| `persistence.selector`                 | Label selector to be applied to the PVC.                                                                                | `{}`                                                |
| `resources`                            | Kubernetes resource requests and limits for the Alertmanager. See [values](./values.yaml) for details.                  | `{}`                                                |
| `securityContext`                      | Security context defines privilege and access control settings for a Pod or Container. See [values](./values.yaml) for details. | `{}`                                                |
| `affinity`                             | Assign affinity rules to the alertmanager instance. See [values](./values.yaml) for details.                            | `{}`                                                |
