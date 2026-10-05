---
title: MaiaPrometheusDown
---

# MaiaPrometheusDown

## Problem

The Maia Prometheus instance (`prometheus-maia-oprom`) is completely down or unreachable. Maia cannot serve any metrics to tenants.

## Impact

Complete customer-facing outage: all PromQL queries return errors. This alert often co-occurs with `OpenstackMaiaUp`.

## Diagnosis

Check the Prometheus pod status in the `maia` namespace:

```bash
kubectl -n maia get pods | grep prometheus
kubectl -n maia describe pod <prometheus-pod>
kubectl -n maia logs <prometheus-pod> --since=30m
```

Check for persistent volume issues that may prevent Prometheus from starting:

```bash
kubectl -n maia get pvc
kubectl -n maia describe pvc <pvc-name>
```

## Resolution Steps

1. Attempt a rollout restart:
   ```bash
   kubectl -n maia rollout restart statefulset/prometheus-maia-oprom
   ```
2. Monitor the pod until it is `Running` and `Ready`.
3. Verify the Maia API also recovers (check `OpenstackMaiaUp`).
4. If Prometheus does not recover (e.g., PVC is full or corrupted), contact the development team.
