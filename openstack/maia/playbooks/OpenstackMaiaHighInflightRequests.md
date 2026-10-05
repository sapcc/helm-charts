---
title: OpenstackMaiaHighInflightRequests
---

# OpenstackMaiaHighInflightRequests

## Problem

Maia has more than 100 concurrent requests in-flight for at least 5 minutes. The normal baseline is 1–4; the historical 24h peak across all regions is 77 (eu-de-1).

## Impact

High concurrency increases CPU and memory pressure on Maia and the underlying Prometheus/Thanos. Response times may degrade. If the load is sustained, it can trigger CPU throttling or OOM conditions.

## Diagnosis

Check the current inflight request count:

```promql
maia_requests_inflight{namespace="maia"}
```

Check which handlers are active and whether any requests are stuck:

```bash
kubectl -n maia logs deployment/maia --since=5m | grep -i "request\|handler\|timeout"
```

Check pod resource usage:

```bash
kubectl -n maia top pods
```

Review the [maia-overview](https://perses.<region>.cloud.sap/projects/observability/dashboards/maia-overview) dashboard for concurrency and latency trends.

## Resolution Steps

1. If a single tenant or automation is running many parallel long-running queries (`query_range` over large time windows), identify them from the logs and contact them to reduce concurrency.
2. If load is evenly distributed, check whether a spike in tenant usage is expected (e.g., a new dashboard deployment).
3. If response times are also degraded, check Prometheus performance (`kubectl -n maia top pod <prometheus-pod>`).
4. If inflight count continues to grow without bound, consider restarting the Maia deployment to clear stuck requests:
   ```bash
   kubectl -n maia rollout restart deployment/maia
   ```
5. If the issue recurs regularly, contact the development team to discuss rate limiting or request queue configuration.
