# Metal Settings Helm Chart

This Helm chart deploys BIOS settings, BIOS versions, and BMC versions for bare-metal servers managed by the metal-operator.

## Overview

The chart generates three types of Kubernetes custom resources:

| Resource Type | Description | Count |
|---------------|-------------|-------|
| `BIOSSettingsSet` | BIOS configuration settings per vendor/model/clusterType | 105 |
| `BIOSVersionSet` | Target BIOS firmware versions per vendor/model | 26 |
| `BMCVersionSet` | Target BMC firmware versions per vendor/model | 26 |

All data (firmware versions, image URIs, model lists) is defined in `values.yaml`. Settings flow content is stored as flat YAML files under `bios_settings/` and referenced by filename via `settingsFileName`.

## Regional Filtering

The chart supports selective deployment of resources using include/exclude filters. This enables:

- **Testing new settings** in specific regions before global rollout
- **Gradual rollouts** by vendor, model, or cluster type
- **Region-specific configurations** with different hardware profiles

## Values

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
    versions:
      included: []
      excluded: []
  items:                           # Defined in values.yaml — override to add/remove entries
    dell:
      - model: poweredge-r640
        version: "2.22.2"
        settingsFileName: dell-default.yaml
        clusterTypes: [cc-kvm-compute, sci-k8s-controlplane, ...]
```

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
    versions:
      included: []
      excluded: []
  items:                           # Defined in values.yaml
    dell:
      - model: poweredge-r640
        version: "2.22.2"
        imageURI: "https://..."
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
    versions:
      included: []
      excluded: []
  items:                           # Defined in values.yaml
    dell:
      - model: poweredge-r640
        version: "7.00.00.183"
        imageURI: "https://..."
```

## Filter Logic

- **Empty `included` list** = include all (default behavior)
- **Non-empty `included` list** = include only specified values
- **`excluded` list** = exclude specified values (applied after include)
- **Multiple filters** are combined with AND logic

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

### UC9: Disable Resource Type Entirely

Disable BIOS settings while keeping versions:

```yaml
biosSettings:
  enabled: false

biosVersions:
  enabled: true

bmcVersions:
  enabled: true
```

### UC10: Multi-Region Deployment Strategy

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
# Count all resources
helm template . | grep -c 'kind: BIOSSettingsSet'

# Count Dell-only resources
helm template . --set 'biosSettings.filters.vendors.included={dell}' | grep -c 'kind: BIOSSettingsSet'

# Preview specific resource
helm template . --set 'biosSettings.filters.vendors.included={dell}' \
  --set 'biosSettings.filters.models.included={poweredge-r7615}' \
  --set 'biosSettings.filters.clusterTypes.included={sci-k8s-controlplane}'
```


## Regional Filtering

The chart supports selective deployment of resources using include/exclude filters. This enables:

- **Testing new settings** in specific regions before global rollout
- **Gradual rollouts** by vendor, model, or cluster type
- **Region-specific configurations** with different hardware profiles

## Values

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
    versions:
      included: []                 # E.g., [1-11-2]
      excluded: []
```

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
    versions:
      included: []
      excluded: []
```

## Filter Logic

- **Empty `included` list** = include all (default behavior)
- **Non-empty `included` list** = include only specified values
- **`excluded` list** = exclude specified values (applied after include)
- **Multiple filters** are combined with AND logic

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

### UC9: Disable Resource Type Entirely

Disable BIOS settings while keeping versions:

```yaml
biosSettings:
  enabled: false

biosVersions:
  enabled: true

bmcVersions:
  enabled: true
```

### UC10: Multi-Region Deployment Strategy

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

## Available Vendors

| Vendor | Models |
|--------|--------|
| `dell` | poweredge-r660, poweredge-r6615, poweredge-r6625, poweredge-r760, poweredge-r7615, poweredge-r7625, poweredge-r860, poweredge-xr7620, poweredge-xr8620, poweredge-xr8640 |
| `hpe` | proliant-dl320-gen11, proliant-dl345-gen11, proliant-dl360-gen10, proliant-dl380-gen11, proliant-dl380-gen12, proliant-dl560-gen10, proliant-dl560-gen11 |
| `lenovo` | thinksystem-sr650v3, thinksystem-sr850p, thinksystem-sr860v3, thinksystem-sr950v3 |

## Available Cluster Types

- `cc-kvm-compute`
- `sci-k8s-controlplane`
- `sci-k8s-management`
- `sci-k8s-runtime`
- `sci-k8s-storage`

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

## Verifying Rendered Resources

Check resource counts before deploying:

```bash
# Count all resources
helm template . | grep -c 'kind: BIOSSettingsSet'

# Count Dell-only resources
helm template . --set 'biosSettings.filters.vendors.included={dell}' | grep -c 'kind: BIOSSettingsSet'

# Preview specific resource
helm template . --set 'biosSettings.filters.vendors.included={dell}' \
  --set 'biosSettings.filters.models.included={poweredge-r7615}' \
  --set 'biosSettings.filters.clusterTypes.included={sci-k8s-controlplane}'
```
