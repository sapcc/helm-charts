# ACI Suite (Umbrella + Subcharts)

This umbrella chart deploys the following ACI components:

1. **aci-cache** (Redis-compatible cache)
2. **aci-data-collector**
3. **aci-netbox-collector**
4. **aci-fault-collector**
5. **aci-correlator**

Each component is packaged as a **separate Helm subchart** under `charts/`, and each
subchart manages **its own Secret** and **its own configuration**, while the umbrella
chart provides shared values such as region, registry, and APIC hosts.

---

## Secret Handling

Each subchart:

- Creates its **own Secret** named after its `fullname`.
- Reads credentials from its own `.Values.aci.*` section:
  - `.Values.aci.aci_user`
  - `.Values.aci.aci_password`
  - `.Values.aci.cache_password`
- The umbrella injects these values through CI or a custom values file.

Example per-subchart ACI block (from umbrella values or CI file):

```yaml
aci-netbox-collector:
  aci:
    cache_password: cache_password

aci-data-collector:
  aci:
    aci_user: aci_user
    aci_password: aci_password
    cache_password: aci_cache_password
```

Each Secret field is validated using Helm’s `required` function:

```gotmpl
aci_user: {{ required ".Values.aci.aci_user variable is missing" .Values.aci.aci_user | b64enc | quote }}
aci_password: {{ required ".Values.aci.aci_password variable is missing" .Values.aci.aci_password | b64enc | quote }}
cache_password: {{ required ".Values.aci.cache_password variable is missing" .Values.aci.cache_password | b64enc | quote }}
```

---

## Region-Aware Filtering (aci-netbox-collector)

The **aci-netbox-collector** supports user-defined base filters in `values.yaml`:

```yaml
env:
  INTERFACE_BASE_FILTER: 'cabled: true, device_role: "aci-leaf"'
  DEVICE_BASE_FILTER: 'device_role: "aci-leaf"'
```

The chart then **appends the umbrella region automatically** (from `global.region`)
inside the ConfigMap template, resulting in effective filters like:

```text
cabled: true, device_role: "aci-leaf", region: "qa-de-1"
device_role: "aci-leaf", region: "qa-de-1"
```

This allows users to keep filter logic flexible while automatically scoping results
per region.

---

## Umbrella Values Overview

Typical `values.yaml` for the umbrella chart:

```yaml
global:
  tld: somewhere.wherever.whenever
  region: eu-de-1
  cluster: no-wh-1
  registry: docker.io

aci:
  aci_hosts: "host1:443,host2:443"
```

Per-chart credentials are passed down like:

```yaml
aci-netbox-collector:
  aci:
    cache_password: password
```

---

## Installing the ACI Suite

```bash
cd aci-suite
helm dependency update .
helm upgrade --install aci ./aci-suite
```

This deploys:

- aci-cache  
- aci-data-collector  
- aci-netbox-collector  
- aci-fault-collector  
- aci-correlator  

in one command.A

---

## Installing Components Individually

### Install only **aci-cache**

```bash
helm upgrade --install aci ./aci-suite   --set aci-data-collector.enabled=false   --set aci-netbox-collector.enabled=false   --set aci-fault-collector.enabled=false   --set aci-correlator.enabled=false
```

### Enable **data-collector**

```bash
helm upgrade aci ./aci-suite --reuse-values   --set aci-data-collector.enabled=true
```

### Enable **netbox-collector**

```bash
helm upgrade aci ./aci-suite --reuse-values   --set aci-netbox-collector.enabled=true
```

### Enable **fault-collector** + **correlator**

```bash
helm upgrade aci ./aci-suite --reuse-values   --set aci-fault-collector.enabled=true   --set aci-correlator.enabled=true
```

---

## Using an External Secret (Optional)

Each subchart supports overriding the generated Secret:

```yaml
aci-netbox-collector:
  existingSecret: my-secret
```

---

## Notes

- `aci.apic_hosts` must be defined in umbrella values.
- Each subchart validates required fields via Helm’s `required`.
- Region for NetBox filters is injected from `global.region`.
- All ACI credentials are passed per-subchart, not globally.
- Structure reflects updated charts and CI injection model.