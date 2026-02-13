# kvm-ha-values-generator

This chart **does not deploy anything**. It generates processed values and configuration files for deploying the public [kvm-ha-service](https://github.com/cobaltcore-dev/kvm-ha-service/) Helm chart with internal dependencies.

## Why does this exist?

The public `kvm-ha-service` chart cannot include internal dependencies or use internal Helm helpers (e.g., `resolve_secret` for Vault integration). This chart:

1. Resolves secrets via the `resolve_secret` helper
2. Generates trust bundle volume mounts
3. Produces a `config.yaml` with internal configuration

## Usage

### 1. Generate values and config

```bash
helm dependency update .

# Generate values.yaml
helm template kvm-ha-values . \
  --show-only templates/generated-values.yaml \
  -f <global-values> \
  -f <region-values> \
  | yq '.data."values.yaml"' - > /tmp/internal-values.yaml

# Generate config.yaml
helm template kvm-ha-values . \
  --show-only templates/generated-values.yaml \
  -f <global-values> \
  -f <region-values> \
  | yq '.data."config.yaml"' - > /tmp/service-config.yaml
```

### 2. Deploy the public chart

```bash
helm upgrade --install kvm-ha-service oci://ghcr.io/<org>/kvm-ha-service \
  -f /tmp/generated-values.yaml \
  --set-file kvmHAservice.config=/tmp/config.yaml
```

## Important Notes

- **Do not `helm install` this chart** - it only generates values
- The generated ConfigMap is never applied to the cluster
- CI/CD pipelines should use the two-step process above
