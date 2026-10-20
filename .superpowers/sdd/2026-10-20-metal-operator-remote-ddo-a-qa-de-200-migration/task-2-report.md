# Task 2 report — metal-operator-remote-ddo

## Result

- Added `system/metal-operator-remote-ddo/tests/render-modes.sh` and made it executable.
- No chart template changes were needed: `helm lint` already passed cleanly.
- `charts/*.tgz` remains ignored by the root `.gitignore`.

## Assertions passed

### Seed render

- `Deployment/metal-operator-controller-manager` present
- `webhook-injector` initContainer present on the seed Deployment
- `Secret/macdb` present
- `Service/metal-operator-metal-registry-service` present
- `Service/metal-operator-remote-webhook-service` present
- `Ingress` present
- Exactly 6 `NetworkPolicy` objects present
- `ConfigMap/remote-kubeconfig` present
- `ValidatingWebhookConfiguration` absent
- `Namespace` absent
- `ClusterRole` absent
- `ClusterRoleBinding` absent

### Shoot render

- At least one `CustomResourceDefinition` present
- `ValidatingWebhookConfiguration` present
- `ValidatingWebhookConfiguration` leaves `caBundle` unset
- `ValidatingWebhookConfiguration` leaves the injector label absent for later transform
- `Namespace/metal-servers` present
- At least 4 `ClusterRoleBinding` objects present
- `ClusterRole/metal-api-viewer` present
- `Deployment` absent
- `Ingress` absent
- `NetworkPolicy` absent

### Mode contract

- Template grep showed only read/guard references to `.Values.mode`
- No template attempted to set `.Values.mode`

## Chart fixes needed

None. The chart rendered and linted successfully once the dependency build ran.

## Dependency / ignore checks

### `git check-ignore -v system/metal-operator-remote-ddo/charts/metal-operator-0.6.2-crds.tgz`

```text
.gitignore:2:*.tgz	system/metal-operator-remote-ddo/charts/metal-operator-0.6.2-crds.tgz
```

### `git status --short --ignored system/metal-operator-remote-ddo/`

```text
?? system/metal-operator-remote-ddo/tests/
!! system/metal-operator-remote-ddo/charts/
```

## `helm lint` output

```text
==> Linting system/metal-operator-remote-ddo
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

## Full `render-modes.sh` output

```text
==> Building chart dependencies
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "deploy-releases-hyperspace-helm" chart repository (https://common.repositories.cloud.sap/artifactory/api/helm/deploy-releases-hyperspace-helm):
	failed to fetch https://common.repositories.cloud.sap/artifactory/api/helm/deploy-releases-hyperspace-helm/index.yaml : 401 Unauthorized
...Unable to get an update from the "unified-runtime-helm" chart repository (https://common.repositories.cloud.sap/artifactory/api/helm/unified-runtime-helm):
	failed to fetch https://common.repositories.cloud.sap/artifactory/api/helm/unified-runtime-helm/index.yaml : 401 Unauthorized
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading metal-operator from repo oci://ghcr.io/ironcore-dev/charts
Pulled: ghcr.io/ironcore-dev/charts/metal-operator:0.6.2-crds
Digest: sha256:24d0dffa0b7eb91a17b6f11ef8696c397701bb34ebff07dcf7e95f799a53940f
Deleting outdated charts
==> Extracting representative values from dualdeploymentoperator-test-qa-de-1.yaml
==> Rendering seed mode
==> Rendering shoot mode
==> Checking mode contract references in templates
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/controller-manager.yaml:1:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/dns-record-template.yaml:1:{{- if and (eq .Values.mode "seed") .Values.dnsRecordTemplate.enabled }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/webhook-injector-rbac.yaml:7:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/webhook-injector-rbac.yaml:60:{{- if eq .Values.mode "shoot" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/ingress.yaml:1:{{- if and (eq .Values.mode "seed") (not .Values.hostNetwork) }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/webhook-service.yaml:1:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/remote-kubeconfig-configmap.yaml:1:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/namespace.yaml:1:{{- if eq .Values.mode "shoot" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/dualdeploymentoperator-cr.yaml:5:  1. .Values.mode is unset (empty string) — the operator is the SOLE injector of mode;
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/dualdeploymentoperator-cr.yaml:21:{{- if and (not .Values.mode) .Values.dualDeploymentOperatorCR.enabled }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/oidc-ias-rbac.yaml:5:{{- if eq .Values.mode "shoot" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/metal-registry-service.yaml:1:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/_helpers.tpl:9:The dual-deployment-operator injects .Values.mode = "seed" | "shoot".
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/_helpers.tpl:14:{{- eq .Values.mode "seed" -}}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/_helpers.tpl:18:{{- eq .Values.mode "shoot" -}}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/macdb.yaml:1:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/remote-kubeconfig.yaml:18:{{- if eq .Values.mode "seed" }}
/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-ddo/templates/networkpolicy.yaml:1:{{- if eq .Values.mode "seed" }}
==> Asserting rendered object sets
PASS: seed render contains Deployment/metal-operator-controller-manager
PASS: seed Deployment includes webhook-injector initContainer
PASS: seed render contains Secret/macdb
PASS: seed render contains Service/metal-operator-metal-registry-service
PASS: seed render contains Service/metal-operator-remote-webhook-service
PASS: seed render contains an Ingress
PASS: seed render contains exactly 6 NetworkPolicy objects
PASS: seed render contains ConfigMap/remote-kubeconfig
PASS: seed render omits ValidatingWebhookConfiguration
PASS: seed render omits Namespace
PASS: seed render omits ClusterRole
PASS: seed render omits ClusterRoleBinding
PASS: shoot render contains at least one CustomResourceDefinition
PASS: shoot render contains a ValidatingWebhookConfiguration
PASS: shoot ValidatingWebhookConfiguration leaves caBundle unset
PASS: shoot ValidatingWebhookConfiguration leaves injector label absent for later transform
PASS: shoot render contains Namespace/metal-servers
PASS: shoot render contains at least 4 ClusterRoleBinding objects
PASS: shoot render contains ClusterRole/metal-api-viewer
PASS: shoot render omits Deployment
PASS: shoot render omits Ingress
PASS: shoot render omits NetworkPolicy
PASS: all render-mode assertions succeeded
PASS: render-modes.sh completed successfully
```
- Added named shoot assertions for metal-operator-webhook-injector ClusterRole/ClusterRoleBinding and oidc-ias ClusterRoleBindings (admin, viewer, metal-viewer, servermaintenance-editor); render-modes.sh passes.
