---
title: OpenstackMaiaKeystoneAvail
---

# OpenstackMaiaKeystoneAvail

## Problem

Maia is experiencing technical errors when communicating with Keystone for token validation. This is distinct from credential failures (`maia_logon_failures_count`) — these are infrastructure-level errors where Keystone is unreachable or returning unexpected responses.

## Impact

All Maia API requests requiring authentication may fail, causing a customer-facing outage. This alert typically co-occurs with broader Keystone degradation in the region.

## Diagnosis

Verify that Keystone is operational in the region:

```bash
openstack token issue
```

Check the Maia API logs for specific Keystone error messages:

```bash
kubectl -n maia logs deployment/maia --since=30m | grep -i keystone
```

Verify the Keystone service catalog entry for Maia:

```bash
openstack catalog show metrics
```

## Resolution Steps

1. If Keystone itself is degraded, coordinate with the Keystone/Identity team. This alert will resolve automatically once Keystone recovers.
2. If Keystone is healthy but Maia cannot reach it, check network connectivity and any proxy configuration in the Maia Helm chart [values.yaml](https://github.com/sapcc/helm-charts/blob/master/openstack/maia/values.yaml).
3. If the catalog entry for Maia is missing or incorrect, reseed it via the region seed pipeline.
4. If the issue cannot be diagnosed locally, contact the development team.
