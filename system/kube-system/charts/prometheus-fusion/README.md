# Prometheus Fusion Helm Chart

If you're on Kubernetes and using helm to manage resources you might have wondered why your application-specific Prometheus recording rules or alerts have to reside in the central Prometheus chart and not with the application?
This operator helps you untangling that.

# Features

- Automatic and periodically discovery of Configmaps containing Prometheus recording rules and alerts using Kubernetes API
- Collect rules and alerts and validates them
- Generates Configmap for Prometheus containing all discovered valid rules

# TL;DR;

```console
$ helm upgrade --install --name prometheus-fusion <path_to_fusion_chart>
```

### Configuration options

| Value                                   | Description                                                                                 | Default                                                                         |
|-----------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `configmapAnnotation`                   | Operator will pickup configmaps with the following annotation                               | `prometheus.io/rule`                                                                                                        |
| `recheckPeriod`                         | How often to sync with chart repositories                                                   | `5`                                                                          |


### Optional configuration options

If the namespace, name of Prometheus configmap are not set, the operator will attempt auto-discovering the configmap annotated with `prometheus.io/configmap: "true"`.

| Value                                   | Description                                                                                 |
|-----------------------------------------|---------------------------------------------------------------------------------------------|
| `prometheusConfigmapNamespace`          | Namespace of Prometheus configmap                                                           |
| `prometheusConfigmapName`               | Name of Prometheus configmap                                                                |
