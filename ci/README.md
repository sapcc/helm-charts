Testing helm charts
-------------------

Helm charts used for the SAP Converged Cloud Enterprise Edition are validated using [concourse](https://concourse-ci.org) and the [helm chart testing utility](https://github.com/helm/chart-testing) with the configuration provided in this folder.  

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
 