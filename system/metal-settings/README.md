# Metal Settings Helm Chart

This Helm chart deploys BIOS/BMC firmware versions and settings for bare-metal servers managed by metal-operator / metal-maintenance-operator.

## Overview

Every vendor/model in `values.yaml` is configured through a single `chain:` map — an ordered sequence of steps, each producing one of four Kubernetes custom resources:

| Kind | Rendered | Purpose |
|------|----------|---------|
| `BMCSettingsSet`  | once per `clusterType` | BMC manager settings (disabled by default) |
| `BMCVersionSet`   | once per model | Target BMC firmware version |
| `BIOSVersionSet`  | once per model | Target BIOS firmware version |
| `BIOSSettingsSet` | once per `clusterType` | BIOS configuration settings |

Additionally, when `bmcSettings.enabled` is true and the corresponding name is set, the chart creates:
- A `ConfigMap` (`clusterConfig.configMapName`) holding cluster-level values (e.g. syslog server).
- A `Secret` (`clusterConfig.hpeLicenseSecretName`) holding the HPE iLO license key.

All data (firmware versions, image URIs, model lists) is defined in `values.yaml`. Settings content is stored as flat YAML files under `bios_settings/` and `bmc_settings/`, referenced by filename via `params.settingsFileName` (or inlined via `params.settingsContent`). See [Machine Inventory](#machine-inventory-machines--the-chain-model) below for the full schema, [CRDVersionControl](#crdversioncontrol--readiness-gate-chaining) for ordered/gated rollouts, and [setMetadataName](#setmetadataname-custom--dynamic-resource-names) for custom/dynamic resource naming.

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
  managedNamespace: "metal-servers"   # Namespace where the ConfigMap/Secret above are deployed
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

When enabled, one `BMCSettingsSet` is generated per `bmc-settings` chain step (once per `clusterType`). Settings content is loaded from `bmc_settings/<settingsFileName>` and rendered via `tpl`, allowing `{{ .Values.clusterConfig.* }}` references inside the files.

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

### Machine Inventory (`machines`) — the Chain Model

All vendor/model data lives under `machines:` in `values.yaml`. This single source drives all four resource kinds. Each model entry is configured entirely through `chain:` — a map of `stepName -> {kind, order, params}`:

```yaml
machines:
  <vendor>:                        # dell | hpe | lenovo
    models:
      <entryName>:                 # usually the model name; use a descriptive suffix (e.g.
                                    # proliant-dl560-gen11-kvm) when one hardware model needs
                                    # multiple entries — see "Multiple entries per model" below.
        model: <model-name>        # Hardware label value + resource name component. Required
                                    # even when entryName == model (keeps selectors correct).
        clusterTypes:               # Only read by Settings kinds (bmc-settings/bios-settings).
          - cc-kvm-compute          # One resource is generated per clusterType listed here.
          - sci-k8s-controlplane    # Use *defaultClusterTypes anchor for the standard 6 types.
        chain:
          <stepName>:
            kind: <Kind>            # BMCSettingsSet | BMCVersionSet | BIOSVersionSet | BIOSSettingsSet
            order: <int>            # Required. Steps are re-sorted by this field (map iteration
                                     # in Go templates is key-sorted, not insertion-ordered).
            params:
              # ... see "Chain step params" table below
```

**Standard step names / orders / kinds** — use these names; omit a step entirely if the model has no data for it (e.g. a model with no BIOS settings file just omits `bios-settings`):

| stepName | order | kind | Rendered |
|----------|------:|------|----------|
| `bmc-settings`  | 1 | `BMCSettingsSet`  | once per `clusterType` |
| `bmc-version`   | 2 | `BMCVersionSet`   | once per model |
| `bios-version`  | 3 | `BIOSVersionSet`  | once per model |
| `bios-settings` | 4 | `BIOSSettingsSet` | once per `clusterType` |

**Chain step `params`:**

| Field | Kinds | Required | Description |
|-------|-------|----------|--------------|
| `version` | all | yes | Firmware/settings version string |
| `settingsFileName` | Settings | one of settingsFileName/settingsContent | File under `bios_settings/` or `bmc_settings/` |
| `settingsContent` | Settings | — | Inline YAML string; wins over `settingsFileName` |
| `imageURI` | Version | yes | Firmware image download URL |
| `serverFilter` | all | no | `{ included: [], excluded: [] }` — narrows the generated resource's selector; empty `included` = all servers, `excluded` wins |
| `setMetadataName` | all | no | Explicit CRD `metadata.name` override, supports `tpl` — see [setMetadataName](#setmetadataname-custom--dynamic-resource-names) below |
| `readinessGates` / `completionConditionType` | all | only when `CRDVersionControl.features.readinessGates.enabled=true` | see [CRDVersionControl](#crdversioncontrol--readiness-gate-chaining) below |

See `machines.dell.models.poweredge-r640.chain` in `values.yaml` for a fully worked example.

**Legacy `bios:`/`bmc:` keys**: models still using the old (pre-chain) `bios:`/`bmc:` blocks are rejected with a hard `fail` at render time — migrate them to `chain:`.

**Multiple entries per model**: when one hardware model needs different settings per `clusterType` split (e.g. different BIOS tuning for KVM vs. Kubernetes clusterTypes), define multiple map keys with distinct `clusterTypes` lists, set `model:` explicitly on each to the shared hardware model name, and put `bmc-version`/`bios-version` (the two *model-scoped*, not clusterType-scoped, kinds) on only ONE of the entries — defining them on more than one entry renders a duplicate resource and fails the build. See `machines.hpe.models.proliant-dl560-gen11-kvm` / `proliant-dl560-gen11-sci` in `values.yaml` for a real example.

### CRDVersionControl — readiness-gate chaining

```yaml
CRDVersionControl:
  apiVersions:
    biosSettingsSet: "metal.ironcore.dev/v1alpha1"
    bmcSettingsSet: "metal.ironcore.dev/v1alpha1"
    biosVersionSet: "metal.ironcore.dev/v1alpha1"
    bmcVersionSet: "metal.ironcore.dev/v1alpha1"
  features:
    readinessGates:
      enabled: false
```

- `apiVersions.*`: which CRD group/version to render the generated resources against. metal-operator (single-group) serves all four kinds under `metal.ironcore.dev/v1alpha1`. metal-maintenance-operator (multigroup) serves them under group-qualified versions: `system.metal.ironcore.dev/v1alpha1` for BIOS kinds, `baseboard.metal.ironcore.dev/v1alpha1` for BMC kinds.
- `features.readinessGates.enabled` (default `false`) changes **how** a model's chain steps are rendered, not where their data comes from:
  - `false` (default): each chain step renders as an independent resource with no `readinessGates`/`completionConditionType` fields — compatible with plain metal-operator.
  - `true`: each model's chain steps render as an ORDERED sequence of resources. A step only starts once the previous step's `completionConditionType` has been patched (`status: True`) onto the related Server(s) — mirroring metal-maintenance-operator's e2e chain test. Every rendered step must then set `params.completionConditionType`, and every non-first step must set `params.readinessGates` (the chart fails fast if either is missing).

**Precondition**: enabling `readinessGates` requires `CRDVersionControl.apiVersions.*` to already point at metal-maintenance-operator's groups — the plain metal-operator group has no `readinessGates`/`completionConditionType` fields at all. The chart fails fast if this precondition isn't met.

Naming convention used throughout `values.yaml` for condition types: `metal.cloud.sap/step<order>-<stepName>-done`, e.g. `metal.cloud.sap/step1-bmc-settings-done`.

### setMetadataName (custom / dynamic resource names)

By default every chain step's resource gets a generated name (`<vendor>-<model>(-<clusterType>)(-<stepName>)`). `params.setMetadataName` overrides this:

- **Settings kinds** (`bmc-settings`/`bios-settings`, rendered once per `clusterType`): the final name is `"<setMetadataName>-<clusterType>"`.
- **Version kinds** (`bmc-version`/`bios-version`, rendered once per model): `setMetadataName` is used verbatim.

It may contain `{{ }}` Go template expressions, resolved via Helm's `tpl` against the chart's root context before use:

```yaml
setMetadataName: "abc-123"                                 # -> abc-123(-<clusterType>)
setMetadataName: "abc-{{ .Values.clusterConfig.region }}"  # -> abc-<region>(-<clusterType>)
```

Dot notation breaks on hyphenated map keys (model/step names) — use `index` instead, e.g. to embed another chain step's `order` number:

```yaml
setMetadataName: >-
  abc-{{ index .Values.machines.dell.models "poweredge-r640" "chain" "bmc-settings" "order" }}
```

Resource names must be unique across the whole chart — a duplicate name (after any `-<clusterType>` suffix) fails the render with an error naming the conflicting entry/model/clusterType.

### Region-Specific Settings Overrides (`settingsContent`)

For specific BIOS or BMC settings overrides (stored in other values files), use `settingsContent` to provide inline YAML instead of referencing a bundled file:

**In region-specific values file** :

```yaml
# Define settings content once via YAML anchors, reference multiple times to avoid duplication
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
        chain:
          bios-settings:
            kind: BIOSSettingsSet
            order: 4
            params:
              version: "2.9.4"
              settingsContent: *myCustomSettings   # Use inline content instead of settingsFileName
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
        chain:
          bmc-settings:
            kind: BMCSettingsSet
            order: 1
            params:
              version: "7.20.60.50"
              settingsContent: *customDellIdrac    # Use region-specific BMC settings override
              serverFilter:
                included: [node001-bb001, node002-bb001]
                excluded: []
```

This example:
- Defines BMC settings content with templated values (e.g., `{{ .Values.clusterConfig.syslogServer }}`)
- Uses `settingsContent` to override the default `settingsFileName` from the base chart
- Enables `bmcSettings` only in this region (keeps it disabled elsewhere)
- Applies the custom BMC settings only to specific nodes via `serverFilter`
- Reuses the same settings across multiple models via YAML anchors

### UC13: Enable Readiness-Gate Chaining

Chain each model's steps so they run strictly in order, gated on the previous step's completion. Requires `CRDVersionControl.apiVersions.*` to already point at metal-maintenance-operator's groups:

```yaml
CRDVersionControl:
  apiVersions:
    biosSettingsSet: "system.metal.ironcore.dev/v1alpha1"
    bmcSettingsSet: "baseboard.metal.ironcore.dev/v1alpha1"
    biosVersionSet: "system.metal.ironcore.dev/v1alpha1"
    bmcVersionSet: "baseboard.metal.ironcore.dev/v1alpha1"
  features:
    readinessGates:
      enabled: true
```

See [CRDVersionControl](#crdversioncontrol--readiness-gate-chaining) above for the full behavior.

### UC14: Give a Resource a Custom / Dynamic Name

```yaml
machines:
  dell:
    models:
      poweredge-r770-nic-slot10:
        model: poweredge-r770
        clusterTypes: [cc-kvm-compute]
        chain:
          bios-settings:
            kind: BIOSSettingsSet
            order: 4
            params:
              version: "1.8.5"
              settingsFileName: dell-r770-nic-slot10.yaml
              setMetadataName: dell-poweredge-r770-nic-slot10
```

See [setMetadataName](#setmetadataname-custom--dynamic-resource-names) above for `tpl`-based dynamic naming.

## Available Cluster Types

- `cc-kvm-compute`
- `sci-k8s-controlplane`
- `sci-k8s-management`
- `sci-k8s-runtime`
- `sci-k8s-storage`
- `cc-ironcore`

See `machines:` in `values.yaml` for the full, current vendor/model inventory — static copies here tend to drift out of date as models are added/retired.

## Settings Files

### BIOS Settings (`bios_settings/`)

BIOS settings flow content is stored as flat YAML files under `bios_settings/`, referenced via `params.settingsFileName` in `values.yaml`:

```
dell-default.yaml             dell-r660-mgmt.yaml            dell-r6715.yaml
dell-r7615.yaml                dell-r770.yaml                 dell-r860-kvm.yaml
hpe-dl380-gen11.yaml           hpe-dl380-gen11-latest-kvm.yaml  hpe-dl380-gen12.yaml
hpe-dl560-gen11-kvm.yaml       hpe-dl560-gen11-latest-kvm.yaml  hpe-dl560-gen11-sci.yaml
lenovo-sr650.yaml              lenovo-sr650-v3.yaml           lenovo-sr655-v3.yaml
lenovo-sr850p.yaml             lenovo-sr850p-kvm.yaml         lenovo-sr850-v3.yaml
lenovo-sr850-v3-new.yaml       lenovo-sr950.yaml              lenovo-sr950-v3.yaml
```

### BMC Settings (`bmc_settings/`)

BMC settings are stored under `bmc_settings/` and also rendered via `tpl`. They may contain `{{ .Values.clusterConfig.* }}` references for the ConfigMap/Secret values. Per-BMC dynamic values (hostname, region, building-block) are resolved at reconcile time via `objectFieldRef` — not Helm templating.

```
dell-default.yaml   dell-r6715.yaml   dell-r770.yaml   hpe-default.yaml   lenovo-default.yaml
```

See each model's `settingsFileName` under `machines:` in `values.yaml` for which file it actually uses.

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
| `bmc_settings_test.yaml` | Tests BMCSettingsSet rendering and filtering |
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
