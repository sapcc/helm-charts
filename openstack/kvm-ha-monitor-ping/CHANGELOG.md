# Changelog

## 0.2.0 - 2026-06-16

- Bump kvm-ha-monitor-ping inner chart to 1.0.0
  - Fix trust bundle handling by switching to extraVolumeMounts/extraVolumes pattern
  - Move config.yaml to ConfigMap; Secret contains only client_secret injected as HA_SERVICE_CLIENT_SECRET via explicit secretKeyRef (no envFrom)

## 0.1.0 - 2026-06-15

- Initial release of umbrella chart
- Includes kvm-ha-monitor-ping 0.2.0, owner-info, and utils as dependencies
