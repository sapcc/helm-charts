# Shoot RBAC parity

Render the shoot manifest for comparison with the legacy bundle:

```bash
helm template argora-operator-remote system/argora-operator-remote-ddo \
  --set mode=shoot
```

TODO: inventory filled by render-parity task.
