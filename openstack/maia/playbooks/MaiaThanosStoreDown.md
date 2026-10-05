---
title: MaiaThanosStoreDown
---

# MaiaThanosStoreDown

## Problem

The Maia Thanos Store API is down. Long-term metric storage results (historical data beyond Prometheus' 24h local retention) will be unavailable.

## Impact

Tenant queries for data older than 24 hours return incomplete results. Real-time and recent queries continue to work normally via the local Prometheus.

## Diagnosis

Check the Thanos Store pod status:

```bash
kubectl -n maia get pods | grep thanos-store
kubectl -n maia logs <thanos-store-pod> --since=30m
```

Check for object storage (Swift/S3) connectivity issues:

```bash
kubectl -n maia describe pod <thanos-store-pod>
```

## Resolution Steps

1. Restart the Thanos Store:
   ```bash
   kubectl -n maia rollout restart statefulset/prometheus-maia-oprom-thanos-store
   ```
2. Monitor the pod until it is `Running` and `Ready`.
3. If the Store fails due to object storage access errors, verify bucket credentials and connectivity in the Helm chart configuration.
4. Note: recent data is still served from Prometheus while the Store is down — only historical data beyond 24h is affected.
5. If the issue persists, contact the development team.
