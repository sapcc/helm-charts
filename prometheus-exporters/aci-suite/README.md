# ACI Suite (Umbrella + Subcharts)

Components (deployed by umbrella):
1) **valkey** (Redis-compatible)
2) **data-collector**
3) **netbox-collector**
4) **fault-collector**
5) **correlator**

All apps use a shared Secret **aci-shared-secrets** for:
- `aci_user`
- `aci_password`
- `cache_password` (Valkey password)

## One-time: create the shared Secret

```bash
kubectl apply -f aci-suite/bootstrap/aci-shared-secrets.yaml
```

## Install everything (all components)

```bash
cd aci-suite
helm dependency update .
helm upgrade --install aci ./
```

## Install components separately (toggle others off)

- Install **valkey** only:
  ```bash
  helm upgrade --install aci ./aci-suite     --set dataCollector.enabled=false     --set netboxCollector.enabled=false     --set faultCollector.enabled=false     --set correlator.enabled=false
  ```

- Then enable **data-collector**:
  ```bash
  helm upgrade aci ./aci-suite --reuse-values     --set dataCollector.enabled=true
  ```

- Enable **netbox-collector**:
  ```bash
  helm upgrade aci ./aci-suite --reuse-values     --set netboxCollector.enabled=true
  ```

- Enable **fault-collector** and **correlator**:
  ```bash
  helm upgrade aci ./aci-suite --reuse-values     --set faultCollector.enabled=true     --set correlator.enabled=true
  ```

## Using an external Secret name

If you prefer to reference an existing Secret:
```yaml
# aci-suite/values.yaml
global:
  auth:
    enabled: true
    existingSecret: aci-shared-secrets   # default
  secretKeys:
    aci_user: aci_user
    aci_password: aci_password
    cache_password: cache_password
```

> When `global.auth.enabled: true`, **Valkey** reads its password from the same shared Secret, and all other apps connect to Valkey with that password.

## Dev mode (no secrets; not recommended)

```yaml
global:
  auth:
    enabled: false
```
Apps fall back to any plaintext values defined in their subchart values.
