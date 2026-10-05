---
title: OpenstackMaiaPrometheusAvail
---

# OpenstackMaiaPrometheusAvail

## Problem

Maia is encountering errors when accessing its underlying Prometheus/TSDB backend. Metric queries may return incomplete or no data.

## Impact

Tenant PromQL queries may return partial results or errors. The Maia API remains reachable but the data it serves is unreliable.

## Diagnosis

Check whether the Maia Prometheus pod is healthy (see also `MaiaPrometheusDown`):

```bash
kubectl -n maia get pods | grep prometheus
kubectl -n maia logs <prometheus-maia-oprom-pod> --since=30m
```

Review the [maia-overview](https://perses.{{ $labels.region }}.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for TSDB error rate trends.

Check the Maia API logs for specific error messages:

```bash
kubectl -n maia logs deployment/maia --since=30m | grep -i "tsdb\|prometheus\|error"
```

## Resolution Steps

1. If Prometheus is running but returning errors, attempt a restart:
   ```bash
   kubectl -n maia rollout restart statefulset/prometheus-maia-oprom
   ```
2. Check for persistent volume issues if Prometheus fails to start after restart:
   ```bash
   kubectl -n maia get pvc
   kubectl -n maia describe pvc <pvc-name>
   ```
3. If errors persist after restart, contact the development team.
