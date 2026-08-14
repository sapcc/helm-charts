# Metal Settings Helm Chart

This Helm chart deploys BIOS settings, BIOS versions, BMC versions, and BMC settings for bare-metal servers managed by the metal-operator.

## Overview

The chart generates four types of Kubernetes custom resources:

| Resource Type | Description | Count |
|---------------|-------------|-------|
| `BIOSSettingsSet` | BIOS configuration settings per vendor/model/clusterType/server | 162 |
| `BIOSVersionSet` | Target BIOS firmware versions per vendor/model/server | 27 |
| `BMCVersionSet` | Target BMC firmware versions per vendor/model/server | 27 |
| `BMCSettingsSet` | BMC manager settings per vendor/model/server (disabled by default) | 162 |

Additionally, when `bmcSettings.enabled` is true, the chart creates:
- A `ConfigMap` (`clusterConfig.configMapName`) holding cluster-level values (e.g. syslog server).
- A `Secret` (`clusterConfig.hpeLicenseSecretName`) holding the HPE iLO license key (if configured).

All data (firmware versions, image URIs, model lists) is defined in `values.yaml`. Settings content is stored as flat YAML files under `bios_settings/` and `bmc_settings/`, referenced by filename via `settingsFileName`.

## Regional Filtering

The chart supports selective deployment of resources using include/exclude filters. This enables:

- **Testing new settings** in specific regions before global rollout
- **Gradual rollouts** by vendor, model, cluster type, or server
- **Region-specific configurations** with different hardware profiles

## Values

### Cluster Configuration (`clusterConfig`)

Cluster-level values shared across templates. These are region/deployment-specific and must be overridden per environment:

```yaml
clusterConfig:
  configMapName: ""             # Name of the ConfigMap created by this chart.
                                # Referenced by Dell BMCSettings variables (syslogServer).
                                # Required when bmcSettings.enabled=true and Dell models are used.
  syslogServer: ""              # Dell iDRAC syslog endpoint, e.g. "remotesyslog.cc.qa-de-1.cloud.sap"
  hpeLicenseSecretName: ""      # Name of the Secret created by this chart for the HPE iLO license.
                                # Required when bmcSettings.enabled=true and HPE models are used.
  hpeLicenseKey: ""             # HPE iLO license key value stored in the Secret above.
                                # In production, inject via Vault / SealedSecrets instead of plain values.
```

### BIOSSettingsSet Configuration

```yaml
biosSettings:
  enabled: true                    # Enable/disable all BIOSSettingsSet resources
  filters:
    vendors:
      included: []                 # Empty = include all. E.g., [dell, hpe, lenovo]
      excluded: []                 # E.g., [lenovo] to exclude Lenovo
    models:
      included: []                 # E.g., [poweredge-r7615, proliant-dl560-gen11]
      excluded: []
    clusterTypes:
      included: []                 # E.g., [sci-k8s-controlplane, cc-kvm-compute]
      excluded: []
    servers:
      included: []                 # E.g., [server-a, server-b]
      excluded: []
    versions:
      included: []
      excluded: []
```

All vendor/model entries are defined under `machines:` in `values.yaml`.

### BIOSVersionSet Configuration

```yaml
biosVersions:
  enabled: true
  filters:
    vendors:
      included: []
      excluded: []
    models:
      included: []
      excluded: []
    servers:
      included: []                 # E.g., [server-a, server-b]
      excluded: []
    versions:
      included: []
      excluded: []
```

### BMCVersionSet Configuration

```yaml
bmcVersions:
  enabled: true
  filters:
    vendors:
      included: []
      excluded: []
    models:
      included: []
      excluded: []
    servers:
      included: []                 # E.g., [server-a, server-b]
      excluded: []
    versions:
      included: []
      excluded: []
```

### BMCSettingsSet Configuration

BMC settings are **disabled by default** and require `clusterConfig` values to be set for each region.

```yaml
bmcSettings:
  enabled: false                   # Enable to deploy BMCSettingsSet resources + ConfigMap/Secret
  filters:
    vendors:
      included: []                 # Empty = include all. E.g., [dell, hpe]
      excluded: []
    models:
      included: []
      excluded: []
    servers:
      included: []                 # E.g., [server-a, server-b]
      excluded: []
    versions:
      included: []
      excluded: []
```

When enabled, one `BMCSettingsSet` is generated per vendor/model entry in `machines[].bmc`. Settings content is loaded from `bmc_settings/<settingsFileName>` and rendered via `tpl`, allowing `{{ .Values.clusterConfig.* }}` references inside the files.

Dynamic per-BMC values (hostname, region, building-block) are resolved at reconcile time via `objectFieldRef` — they are **not** Helm values and require no chart configuration.

#### Enabling BMCSettings for Dell

```yaml
bmcSettings:
  enabled: true

clusterConfig:
  configMapName: metal-bmc-settings
  syslogServer: "remotesyslog.cc.qa-de-1.cloud.sap"
```

#### Enabling BMCSettings for HPE (with license key)

```yaml
bmcSettings:
  enabled: true

clusterConfig:
  hpeLicenseSecretName: hpe-ilo-license
  hpeLicenseKey: "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"  # or inject via Vault
```

### Machine Inventory (`machines`)

All vendor/model data is defined under `machines:` in `values.yaml`. This single source drives all four resource types — BIOS settings, BIOS versions, BMC versions, and BMC settings. Each entry defines what to deploy for that model.

```yaml
machines:
  <vendor>:                        # dell | hpe | lenovo
    models:
      - model: <model-name>        # Used as the label selector value and resource name suffix.
        clusterTypes:              # List of cluster types this model applies to (BIOS only).
          - cc-kvm-compute         # Use *defaultClusterTypes anchor for the standard set.
          - sci-k8s-controlplane
        bios:
          version: "2.22.2"        # Target BIOS firmware version gate.
          settingsFileName: dell-default.yaml  # File under bios_settings/ to use for BIOSSettingsSet.
          imageURI: "https://..."  # Firmware image download URL for BIOSVersionSet.
        bmc:
          version: "7.00.00.183"   # Target BMC firmware version gate.
          settingsFileName: dell-default.yaml  # File under bmc_settings/ to use for BMCSettingsSet.
          imageURI: "https://..."  # Firmware image download URL for BMCVersionSet.
```

**Key rules:**
- A model entry with both `bios:` and `bmc:` blocks generates resources for all four types (subject to `enabled` flags and filters).
- `clusterTypes` only affects `BIOSSettingsSet` — one resource is generated per cluster type. BIOS/BMC version and BMC settings resources are model-scoped (no cluster type dimension).
- `settingsFileName` references a file in `bios_settings/` or `bmc_settings/` respectively. Multiple models can share the same file.
- The `*defaultClusterTypes` YAML anchor expands to the standard six cluster types defined at the top of `values.yaml`.
- `servers` filters are rendered as selector `matchExpressions` on `kubernetes.metal.cloud.sap/name`.
- `included` uses `operator: In`, `excluded` uses `operator: NotIn`.
- Unlike vendor/model/version/clusterType filters, `servers` narrows the generated resource selector rather than deciding whether Helm renders the resource at all.

### Region-Specific Settings Overrides (`settingsContent`)

For specific BIOS or BMC settings overrides (stored in other values files), use `settingsContent` to provide inline YAML instead of referencing a bundled file:

**In region-specific values file** :

```yaml
# Define BIOS settings content once via YAML anchors, reference multiple times to avoid duplication
_biosSettingsContent:
  myCustomSettings: &myCustomSettings |
    settingsFlow:
    - name: myFlow
      priority: 10
      settings:
        Setting1: Value1
        Setting2: Value2

machines:
  dell:
    models:
      poweredge-r860-custom:
        model: poweredge-r860
        clusterTypes: [cc-kvm-compute]
        bios:
          version: "2.9.4"
          settingsContent: *myCustomSettings      # Use inline content instead of settingsFileName
          imageURI: "https://..."
          settingsParams:
            serverFilter:
              included: [node003-bb086, node009-bb086]
              excluded: []
```

**Behavior:**
- If `settingsContent` is provided, it is used (takes precedence over `settingsFileName`)
- If `settingsContent` is absent, the chart falls back to `settingsFileName` (loads from bundled `bios_settings/` or `bmc_settings/`)
- Use YAML anchors (`&name`) and aliases (`*name`) to define settings once and reference them multiple times — this prevents duplication across region-specific overrides
- Helm deep-merges region-specific values on top of base values, so only override entries that differ
## Filter Logic

- **Empty `included` list** = include all (default behavior)
- **Non-empty `included` list** = include only specified values
- **`excluded` list** = exclude specified values (applied after include)
- **Multiple filters** are combined with AND logic
- **`servers` filters** are rendered as selector `matchExpressions` on `kubernetes.metal.cloud.sap/name`
- `included` uses `operator: In`, `excluded` uses `operator: NotIn`
- Unlike vendor/model/version/clusterType filters, `servers` narrows the generated resource selector rather than deciding whether Helm renders the resource at all

## Use Case Examples

### UC1: Deploy Everything (Default)

Deploy all resources to all regions:

```yaml
# values.yaml (default)
biosSettings:
  enabled: true
  filters:
    vendors:
      included: []
      excluded: []
```

### UC2: Deploy Only Dell Resources

Test Dell-specific settings in a region:

```yaml
biosSettings:
  filters:
    vendors:
      included: [dell]

biosVersions:
  filters:
    vendors:
      included: [dell]

bmcVersions:
  filters:
    vendors:
      included: [dell]
```

### UC3: Deploy Everything Except HPE

Exclude HPE while deploying all other vendors:

```yaml
biosSettings:
  filters:
    vendors:
      excluded: [hpe]
```

### UC4: Deploy Specific Model

Deploy only PowerEdge R7615 settings:

```yaml
biosSettings:
  filters:
    models:
      included: [poweredge-r7615]
```

### UC5: Deploy Specific Cluster Type

Deploy only control plane settings:

```yaml
biosSettings:
  filters:
    clusterTypes:
      included: [sci-k8s-controlplane]
```

### UC6: Combination Filter (Targeted Rollout)

Deploy Dell PowerEdge R7615 control plane settings only:

```yaml
biosSettings:
  filters:
    vendors:
      included: [dell]
    models:
      included: [poweredge-r7615]
    clusterTypes:
      included: [sci-k8s-controlplane]
```

This produces exactly 1 BIOSSettingsSet resource.

### UC7: Include Vendor but Exclude Specific Model

Deploy all Dell models except PowerEdge R7615:

```yaml
biosSettings:
  filters:
    vendors:
      included: [dell]
    models:
      excluded: [poweredge-r7615]
```

### UC8: Exclude Specific Cluster Type

Deploy to all cluster types except cc-kvm-compute:

```yaml
biosSettings:
  filters:
    clusterTypes:
      excluded: [cc-kvm-compute]
```

### UC9: Deploy Specific Servers

Target only two named servers:

```yaml
biosSettings:
  filters:
    servers:
      included: [server-a, server-b]

bmcVersions:
  filters:
    servers:
      excluded: [server-c]
```

### UC10: Disable Resource Type Entirely

Disable BIOS settings while keeping versions:

```yaml
biosSettings:
  enabled: false

biosVersions:
  enabled: true

bmcVersions:
  enabled: true
```

### UC11: Multi-Region Deployment Strategy

**Region A (Production)** - Full deployment:
```yaml
biosSettings:
  enabled: true
  filters:
    vendors:
      included: []  # All vendors
```

**Region B (Testing)** - Only Dell for testing:
```yaml
biosSettings:
  enabled: true
  filters:
    vendors:
      included: [dell]
```

**Region C (Staging)** - New Lenovo settings:
```yaml
biosSettings:
  enabled: true
  filters:
    vendors:
      included: [lenovo]
```

### UC12: Override Region-Specific BMC Settings

In a region-specific values file (e.g., `kube-secrets`), override BMC settings for specific nodes and enable BMC settings deployment:

```yaml
# kube-secrets/values/helm/metalapi/<region>/<cluster>/metal-settings.yaml

# Define BMC settings content once via YAML anchors
_bmcSettingsContent:
  customDellIdrac: &customDellIdrac |
    settingsFlow:
    - name: syslogConfiguration
      priority: 10
      settings:
        SyslogServer: "{{ .Values.clusterConfig.syslogServer }}"
        SyslogPort: 514
    - name: snmpConfiguration
      priority: 20
      settings:
        SnmpCommunity: "public"

bmcSettings:
  enabled: true

clusterConfig:
  configMapName: metal-bmc-settings
  syslogServer: "syslog.region-qa-de-1.cloud.sap"

machines:
  dell:
    models:
      poweredge-r860:
        model: poweredge-r860
        clusterTypes: *defaultClusterTypes
        bmc:
          version: "7.20.60.50"
          settingsContent: *customDellIdrac    # Use region-specific BMC settings override
          settingsParams:
            serverFilter:
              included: [node001-bb001, node002-bb001]
              excluded: []
          imageURI: "https://<repo-address>/poweredge-r860/iDRAC-7.20.60.50.EXE"
```

This example:
- Defines BMC settings content with templated values (e.g., `{{ .Values.clusterConfig.syslogServer }}`)
- Uses `settingsContent` to override the default `settingsFileName` from the base chart
- Enables `bmcSettings` only in this region (keeps it disabled elsewhere)
- Applies the custom BMC settings only to specific nodes via `serverFilter`
- Reuses the same settings across multiple models via YAML anchors

## Available Vendors and Models

### BIOSSettings / BIOSVersions

| Vendor | Models |
|--------|--------|
| `dell` | poweredge-r640, poweredge-r660, poweredge-r6715, poweredge-r740, poweredge-r740xd, poweredge-r760, poweredge-r7615, poweredge-r770, poweredge-r7715, poweredge-r840, poweredge-r860, poweredge-xe9680 |
| `hpe` | proliant-dl380-gen11, proliant-dl560-gen11 *(settings)*; proliant-dl320-gen11, proliant-dl345-gen11, proliant-dl360-gen10, proliant-dl380-gen11, proliant-dl380-gen12, proliant-dl560-gen10, proliant-dl560-gen11 *(versions)* |
| `lenovo` | thinksystem-sr650, thinksystem-sr650-v3, thinksystem-sr655-v3, thinksystem-sr850p, thinksystem-sr850-v3, thinksystem-sr950, thinksystem-sr950-v3 |

### BMCVersions

| Vendor | Models |
|--------|--------|
| `dell` | poweredge-r640, poweredge-r660, poweredge-r6715, poweredge-r740, poweredge-r740xd, poweredge-r760, poweredge-r7615, poweredge-r770, poweredge-r7715, poweredge-r840, poweredge-r860, poweredge-xe9680 |
| `hpe` | proliant-dl320-gen11, proliant-dl345-gen11, proliant-dl360-gen10, proliant-dl380-gen11, proliant-dl380-gen12, proliant-dl560-gen10, proliant-dl560-gen11 |
| `lenovo` | thinksystem-sr650, thinksystem-sr650-v3, thinksystem-sr655-v3, thinksystem-sr850p, thinksystem-sr850-v3, thinksystem-sr950, thinksystem-sr950-v3 |

## Available Cluster Types

- `cc-kvm-compute`
- `sci-k8s-controlplane`
- `sci-k8s-management`
- `sci-k8s-runtime`
- `sci-k8s-storage`

## Settings Files

### BIOS Settings (`bios_settings/`)

BIOS settings flow content is stored as flat YAML files under `bios_settings/` and referenced via `settingsFileName` in `values.yaml`:

| File | Used by |
|------|---------|
| `dell-default.yaml` | All Dell models except R7615 |
| `dell-r7615.yaml` | Dell PowerEdge R7615 (different NIC config) |
| `hpe-dl380-gen11.yaml` | HPE ProLiant DL380 Gen11 (all cluster types) |
| `hpe-dl560-gen11-kvm.yaml` | HPE ProLiant DL560 Gen11 — `cc-kvm-compute` (AdvancedEcc) |
| `hpe-dl560-gen11-sci.yaml` | HPE ProLiant DL560 Gen11 — `sci-k8s-*` (FastFaultTolerantADDDC) |
| `lenovo-sr650.yaml` | Lenovo ThinkSystem SR650 |
| `lenovo-sr650-v3.yaml` | Lenovo ThinkSystem SR650 V3 |
| `lenovo-sr655-v3.yaml` | Lenovo ThinkSystem SR655 V3 |
| `lenovo-sr850p.yaml` | Lenovo ThinkSystem SR850p |
| `lenovo-sr850-v3.yaml` | Lenovo ThinkSystem SR850 V3 |
| `lenovo-sr950.yaml` | Lenovo ThinkSystem SR950 |
| `lenovo-sr950-v3.yaml` | Lenovo ThinkSystem SR950 V3 |

### BMC Settings (`bmc_settings/`)

BMC settings are stored under `bmc_settings/` and also rendered via `tpl`. They may contain `{{ .Values.clusterConfig.* }}` references for the ConfigMap/Secret names. Per-BMC dynamic values (hostname, region, labels) are resolved at reconcile time via `objectFieldRef` variables — not Helm templating.

| File | Used by | Dynamic values resolved at reconcile |
|------|---------|---------------------------------------|
| `dell-default.yaml` | All Dell models | `NodeName`, `BB`, `Region` (BMC labels); `SyslogServer` (ConfigMap) |
| `hpe-default.yaml` | All HPE models | `NodeName`, `BB` (BMC labels); `LicenseKey` (Secret) |
| `lenovo-default.yaml` | All Lenovo models | `BmcName` (BMCSettings spec); `Region` (BMC label) |

## CI Integration

The chart includes CI test values in the `ci/` directory for automated testing:

| File | Description |
|------|-------------|
| `test-values.yaml` | Default configuration - deploys all resources |
| `filter-vendor-values.yaml` | Tests vendor filtering (Dell only) |
| `filter-targeted-values.yaml` | Tests combination filtering (specific vendor + model + clusterType) |

These files are used by [chart-testing](https://github.com/helm/chart-testing) in the CI pipeline to validate:
- Helm chart linting
- Template rendering with different filter configurations

## Testing

Run unit tests with helm-unittest:

```bash
helm unittest .
```

Unit test files are located in `tests/`:

| File | Description |
|------|-------------|
| `bios_settings_test.yaml` | Tests BIOSSettingsSet rendering and filtering |
| `bios_versions_test.yaml` | Tests BIOSVersionSet rendering and filtering |
| `bmc_versions_test.yaml` | Tests BMCVersionSet rendering and filtering |

## Verifying Rendered Resources

Check resource counts before deploying:

```bash
# Count all BIOS resources
helm template . | grep -c 'kind: BIOSSettingsSet'
# Count Dell-only BIOS resources
helm template . --set 'biosSettings.filters.vendors.included={dell}' | grep -c 'kind: BIOSSettingsSet'

# Preview specific resource
helm template . --set 'biosSettings.filters.vendors.included={dell}' \
  --set 'biosSettings.filters.models.included={poweredge-r7615}' \
  --set 'biosSettings.filters.clusterTypes.included={sci-k8s-controlplane}'
```
