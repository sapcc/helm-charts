# ACI Suite (Umbrella + Subcharts)

This umbrella chart deploys the following ACI components:

1) **valkey** (Redis-compatible cache)  
2) **data-collector**  
3) **netbox-collector**  
4) **fault-collector**  
5) **correlator**

Each component is packaged as a **separate Helm subchart** under `charts/`, and each subchart manages **its own Secret**, following the same pattern used in the `netapp-exporter` suite.

All subcharts:

- Create their **own Secret** named after their `fullname` value  
- Populate the Secret using umbrella-level `global.*` values:  
  - `global.aci_exporter_user`  
  - `global.aci_exporter_password`  
  - `global.cache_password`  
- Read the list of APIC hosts from umbrella value:  
  - `aci.apic_hosts`  
  - Exposed to templates via:  
    ```yaml
    {{- $apicHosts := required "missing $.Values.aci.apic_hosts" $.Values.aci.apic_hosts }}
    ```  

Valkey uses the same `cache_password` and exposes the Redis-compatible service used by the other collectors.

## Umbrella Values Overview

```yaml
global:
  prometheus: infra-collector
  namespace: infra-monitoring
  linkerd_requested: false

  registry: keppel.eu-de-1.cloud.sap/ccloud-netops-observabilty

  aci_exporter_user: "username"
  aci_exporter_password: "password"
  cache_password: "password"

aci:
  apic_hosts:
    - 10.17.125.32:443
    - 10.17.125.30:443
```

## Installing the ACI Suite

```bash
cd aci-suite
helm dependency update .
helm upgrade --install aci ./aci-suite
```

This deploys:

- valkey  
- data-collector  
- netbox-collector  
- fault-collector  
- correlator  

in a single command.

## Installing Components Individually (toggle via values)

### Install **valkey only**
```bash
helm upgrade --install aci ./aci-suite   --set data-collector.enabled=false   --set netbox-collector.enabled=false   --set fault-collector.enabled=false   --set correlator.enabled=false
```

### Enable **data-collector**
```bash
helm upgrade aci ./aci-suite --reuse-values   --set data-collector.enabled=true
```

### Enable **netbox-collector**
```bash
helm upgrade aci ./aci-suite --reuse-values   --set netbox-collector.enabled=true
```

### Enable **fault-collector** and **correlator**
```bash
helm upgrade aci ./aci-suite --reuse-values   --set fault-collector.enabled=true   --set correlator.enabled=true
```

## Using an External Secret (optional)

You can override the default generated secrets:

```yaml
data-collector:
  existingSecret: my-data-collector-secret
```

## Notes

- APIC hosts must be defined in umbrella values under `aci.apic_hosts`.  
- Each subchart validates this with Helm’s `required` function.  
- Credentials and cache passwords are consistently passed via per-chart Secrets.  
- Matches structure of `netapp-exporter` umbrella suites.
