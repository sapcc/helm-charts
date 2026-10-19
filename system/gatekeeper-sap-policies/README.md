# gatekeeper-sap-policies

OPA Gatekeeper ConstraintTemplates and Constraints for SAP-specific admission control, carved out of the legacy `system/gatekeeper` monolith for deployment via Greenhouse (PluginDefinition `gatekeeper-sap-policies` in the internal greenhouse-extensions repo).

Requires OPA Gatekeeper installed on the cluster. The `region-value-mismatch` and `region-value-missing` policies additionally require `gatekeeper-doop` (helm-manifest-parser) at runtime.

## Policies

| Policy | Kind | Default | Needs DOOP |
|--------|------|---------|------------|
| `restrict-monsoon3-namespace` | GkRestrictMonsoon3Namespace | enabled, dryrun | no |
| `outdated-mirrors` | GkOutdatedMirrors | enabled, dryrun | no |
| `prometheusrule-alert-labels` | GkPrometheusruleAlertLabels | enabled, dryrun | no |
| `region-value-mismatch` | GkRegionValueMismatch | disabled | yes |
| `region-value-missing` | GkRegionValueMissing | disabled | yes |

All policies default to `enforcementAction: dryrun`. Set `policies.<name>.enforcementAction` to `warn` or `deny` to enforce, and `policies.<name>.enabled` to toggle.
