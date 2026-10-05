---
title: MaiaThanosQueryDown
---

# MaiaThanosQueryDown

## Problem

The Maia Thanos Querier is down. All Maia API metric queries are routed through the Thanos Querier — when it is unavailable, Maia cannot return any metrics to tenants.

## Impact

Complete customer-facing outage: all PromQL queries, series lookups, and label queries return errors. Functionally equivalent to `MaiaPrometheusDown`.

## Diagnosis

Check the Thanos Querier pod status:

```bash
kubectl -n maia get pods | grep thanos-query
kubectl -n maia logs <thanos-query-pod> --since=30m
```

Look for configuration errors or connectivity issues with Thanos Store or Prometheus:

```bash
kubectl -n maia describe pod <thanos-query-pod>
```

## Resolution Steps

1. Restart the Thanos Querier deployment:
   ```bash
   kubectl -n maia rollout restart deployment/prometheus-maia-oprom-thanos-query
   ```
2. Verify the pod recovers and metrics are accessible again via the Maia API.
3. If the Querier fails to start (configuration error, missing endpoint), check the Helm chart configuration and redeploy via the [maia pipeline](https://ci1.eu-de-2.cloud.sap/teams/monitoring/pipelines/maia).
4. If the issue cannot be resolved, contact the development team.
