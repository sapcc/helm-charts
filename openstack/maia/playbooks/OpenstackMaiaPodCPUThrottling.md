---
title: OpenstackMaiaPodCPUThrottling
---

# OpenstackMaiaPodCPUThrottling

## Problem

A container in the `maia` namespace is being CPU-throttled more than 80% of the time over the past hour for at least 15 minutes. This degrades API response times.

## Impact

Maia API response times increase. Tenants experience slower metric queries, but the service remains available.

## Diagnosis

Identify the affected pod and container from the alert labels `{{ $labels.pod }}/{{ $labels.container }}`.

Check current resource usage:

```bash
kubectl -n maia top pod <pod-name>
```

Review the [maia-overview](https://perses.{{ $labels.region }}.cloud.sap/projects/observability/dashboards/maia-overview) dashboard to check the status of Maia components.

## Resolution Steps

1. If throttling is sustained, increase CPU resource `limits` and `requests` in the Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml).
2. Alternatively, scale up the number of replicas for the affected deployment.
3. Apply changes via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia) and monitor that throttling subsides.
4. If the issue persists, contact the SCI Observability team.
