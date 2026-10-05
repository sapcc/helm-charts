---
title: OpenstackMaiaHighAuthFailureRate
---

# OpenstackMaiaHighAuthFailureRate

## Problem

Maia is seeing more than 5 failed authentication attempts per second sustained for at least 15 minutes. This is well above the normal baseline of 0.1–0.3/s.

## Impact

No direct service degradation — failed authentications are rejected before consuming significant resources. However, a sustained wave of failures may indicate a brute-force attempt, a misconfigured automation, or a credential rotation problem affecting real tenants.

## Diagnosis

Check the current failure rate by region:

```promql
rate(maia_logon_failures_count{namespace="maia"}[5m])
```

Check Maia API logs to see which user or IP is generating the failures:

```bash
kubectl -n maia logs deployment/maia --since=30m | grep -i "logon\|failure\|unauthorized" | head -50
```

Look for patterns: repeated failures from a single user, domain, or source IP suggest a specific misconfigured client.

## Resolution Steps

1. If the source is a misconfigured automation or monitoring tool, identify the owner and correct their credentials.
2. If it looks like credential rotation happened without updating a dependent service, notify the affected team.
3. If the pattern suggests a brute-force attempt from an external source, coordinate with the security team.
4. If failures are coming from a legitimate internal source that can't be fixed immediately, no action is required — Maia will reject them. Monitor to ensure the rate does not continue to rise.
