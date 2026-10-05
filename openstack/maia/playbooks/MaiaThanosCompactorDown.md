---
title: MaiaThanosCompactorDown
---

# MaiaThanosCompactorDown

## Problem

The Maia Thanos Compactor is down. Block compaction in long-term storage is paused.

## Impact

No immediate customer impact. Over time, uncompacted blocks increase query scan costs for long-range queries. Resolve at normal priority.

## Diagnosis

Check the Thanos Compactor pod status:

```bash
kubectl -n maia get pods | grep thanos-compactor
kubectl -n maia logs <thanos-compactor-pod> --since=30m
```

Look for object storage errors or configuration issues:

```bash
kubectl -n maia describe pod <thanos-compactor-pod>
```

## Resolution Steps

1. Restart the Thanos Compactor:
   ```bash
   kubectl -n maia rollout restart deployment/prometheus-maia-oprom-thanos-compactor
   ```
2. Monitor the pod until it is `Running`. No immediate user impact while resolving.
3. If the Compactor fails due to object storage access errors, verify bucket credentials and connectivity in the Helm chart configuration.
4. If the Compactor does not recover, contact the development team.
