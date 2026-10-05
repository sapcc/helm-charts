---
title: OpenstackMaiaUp
---

# OpenstackMaiaUp

## Problem

The Maia API endpoint has been unreachable for more than 10 minutes. Maia is effectively down and all tenant metric queries are failing.

## Impact

Complete customer-facing outage: all PromQL queries, series lookups, and label queries return errors.

## Diagnosis

Check pod status and logs immediately:

```bash
kubectl -n maia get pods
kubectl -n maia logs deployment/maia
```

Logs are also available in [OpenSearch Dashboards](https://logs.<region>.cloud.sap/app/data-explorer/discover) filtered by `resource.k8s.namespace.name: maia`.

Look for crash loops or failed readiness probes:

```bash
kubectl -n maia describe pod <maia-pod>
```

Verify the Maia service and ingress are healthy:

```bash
kubectl -n maia get svc,ingress
```

## Resolution Steps

1. If pods are crash-looping, check the logs for the root cause (configuration error, missing secret, Keystone connectivity).
2. Attempt a rollout restart if logs show no clear cause:
   ```bash
   kubectl -n maia rollout restart deployment/maia
   ```
3. If the service does not recover after restart, contact the development team.
