Testing helm charts
-------------------

Helm charts used for the SAP Converged Cloud are validated the [helm chart testing utility](https://github.com/helm/chart-testing) with the configuration provided in this folder and [kube-score](https://github.com/zegl/kube-score) to make our charts more secure and resilient. 
Assuming a chart looks like this:
```
.
└── myChart
    ├── ci
    │   └── test-values.yaml
    ├── aggregations
    │   └── *.rules
    ├── alerts
    │   └── *.alerts
    ├── templates
    │   └── ...
    ...
    ├── Chart.yaml
    └── values.yaml
```

A `Chart.yaml` must have the following mandatory attributes:
```yaml
# The chart API version. 
apiVersion: v1

# Version of the application deployed with this chart.
appVersion: "1.0"

# A short description of the chart.
description: mychart

# The name of the chart.
name: chart-name

# The version of the chart.
version: 0.1.0

# List of maintainers for this chart.
maintainers:
  - name: github-handle
```

# Providing test values

The chart test toolkit will use every `*-values.yaml` provided in the `ci` folder of the chart.  

# What is tested

1. Lint helm chart
    
    The helm chart is linted according to the [configuration](config.yaml).

2. Prometheus alert- & aggregation rules

    If Prometheus alert- (`*.alerts`) or aggregation rules `(*.rules)` are part of the Helm chart, they are validated using the [promtool](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/#syntax-checking-rules).


# Running the tests locally

Tests can be done locally using the Docker image found in the `sapcc/chart-testing` repository.
The tag `$version-promtool` indicates a pre-installed [promtool](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/#syntax-checking-rules).

Example: 
```
docker run --rm -v $helm-charts.git:/charts sapcc/chart-testing:v2.3.3-sapcc sh -c "cd charts && ct lint --chart-yaml-schema ci/chart_schema.yaml --lint-conf ci/lintconf.yaml --config ci/config.yaml --charts openstack/nova"
```