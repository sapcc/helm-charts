## 1. Project scaffolding

- [x] 1.1 Create directory structure: `system/kustomize/metal-operator-remote/{host/base,host/overlays,remote/upstream/crds-and-rbac,remote/upstream/webhooks/source,remote/custom/base,remote/custom/overlays,components/webhook-injector}`
- [x] 1.2 Create `remote/upstream/crds-and-rbac/kustomization.yaml` referencing upstream `config/crd` + `config/rbac` at pinned tag with Role→ClusterRole patches
- [x] 1.3 Create `remote/upstream/webhooks/source/kustomization.yaml` referencing upstream `config/webhook` at pinned tag
- [x] 1.4 Verify `kustomize build remote/upstream/crds-and-rbac/` succeeds and produces expected CRDs + RBAC

## 2. Webhook URL rendering

- [x] 2.1 Create `remote/upstream/webhooks/kustomization.yaml` referencing `manifests-url-based.yaml`
- [x] 2.2 Write the `yq` command to transform service→URL and generate `manifests-url-based.yaml`
- [x] 2.3 Verify generated webhook manifests match current `metal-operator-remote/webhooks.yaml` content

## 3. Webhook-injector Component

- [x] 3.1 Create `components/webhook-injector/kustomization.yaml` (kind: Component)
- [x] 3.2 Create `components/webhook-injector/sidecar.yaml` with full initContainer spec (image, args, ports, probes, resources, volumeMounts)
- [x] 3.3 Verify Component can be included by a test kustomization and produces correct initContainer in output

## 4. Host base resources

- [x] 4.1 Create `host/base/kustomization.yaml` referencing upstream `config/manager`, components, patches, and all local resources
- [x] 4.2 Create `host/base/manager-remote-patch.yaml` (env vars, volumes, pod labels, strategy, serviceAccountName, securityContext)
- [x] 4.3 Create `host/base/manager-webhook-patch.yaml` (webhook port, certs emptyDir, macdb volume)
- [x] 4.4 Create local resource files: `webhook-service.yaml`, `metal-registry-service.yaml`, `networkpolicy.yaml`, `webhook-injector-rbac.yaml`
- [x] 4.5 Create local resource files: `ingress.yaml`, `remote-kubeconfig-configmap.yaml`, `remote-serviceaccount-secret.yaml`, `macdb-secret.yaml`, `rotate-kubeconfig-secret.yaml`, `webhook-config.yaml`
- [x] 4.6 Verify `kustomize build host/base/` succeeds and produces all expected resource kinds (Deployment, Services, Ingress, NetworkPolicy, ConfigMaps, Secrets, SA, Role, RoleBinding)

## 5. Host overlay example

- [x] 5.1 Create `host/overlays/rt-eu-de-1/kustomization.yaml` with patches for ingress domain, apiserver URL, macdb, remote CA, image tags, and controller args
- [x] 5.2 Verify `kustomize build host/overlays/rt-eu-de-1/` succeeds and renders correct environment-specific values

## 6. Remote custom resources

- [x] 6.1 Create `remote/custom/base/kustomization.yaml` with `namespace.yaml` and `rbac.yaml`
- [x] 6.2 Create `remote/custom/base/namespace.yaml` (Namespace: metal-servers)
- [x] 6.3 Create `remote/custom/base/rbac.yaml` with placeholder values for IAS groups and LDAP users
- [x] 6.4 Create `remote/custom/overlays/rt-eu-de-1/kustomization.yaml` with patches for IAS group names and LDAP admin users
- [x] 6.5 Verify `kustomize build remote/custom/overlays/rt-eu-de-1/` succeeds

## 7. ManagedResource wrapping

- [x] 7.1 Write `scripts/wrap-managedresources.sh` that takes multi-document YAML on stdin and produces ManagedResource+Secret pairs
- [x] 7.2 Generate `remote/upstream/crds-and-rbac/managedresources.yaml` using the script
- [x] 7.3 Generate `remote/upstream/webhooks/managedresources.yaml` using the script
- [x] 7.4 Verify generated ManagedResource format matches current `templates/managedresource.yaml` output

## 8. Makefile integration

- [x] 8.1 Add `regen-metal-operator-remote`, `regen-metal-operator-remote-crds`, `regen-metal-operator-remote-webhooks` targets to `system/Makefile`
- [x] 8.2 Verify `make regen-metal-operator-remote` regenerates all pre-rendered files correctly

## 8b. Top-level per-environment overlay

- [x] 8b.1 Create `overlays/rt-eu-de-1/kustomization.yaml` combining host overlay + remote upstream ManagedResources + remote custom overlay
- [x] 8b.2 Verify `kustomize build overlays/rt-eu-de-1/` produces all resources (host + remote ManagedResources) in a single output
- [x] 8b.3 Verify `kubectl apply -k overlays/rt-eu-de-1/ --dry-run=client` succeeds

## 9. Equivalence verification

- [x] 9.1 Compare `kustomize build host/overlays/rt-eu-de-1/` output against `helm template metal-operator-remote` with equivalent values — document differences
- [x] 9.2 Compare `kustomize build remote/upstream/crds-and-rbac/` output against current `managedresources/crds-and-rbac.yaml` — document differences
- [x] 9.3 Compare webhook output against current `webhooks.yaml` — document differences
- [x] 9.4 Write findings summary: what works, what doesn't, blockers identified

## 10. Documentation

- [x] 10.1 Create `system/kustomize/metal-operator-remote/README.md` — operator guide covering: prerequisites, upgrading upstream version, regenerating remote resources, adding a new environment overlay, deploying, and troubleshooting

## 11. Remote custom RBAC prod/qa Components

- [ ] 11.1 Update `remote/custom/base/rbac.yaml` to use `MUST_BE_SET_IN_OVERLAY` placeholder for OIDC group names in ClusterRoleBinding subjects
- [ ] 11.2 Create `remote/custom/components/prod/kustomization.yaml` (kind: Component) that patches group names to `CC_IAS_CONTROLPLANE_PROD_ADMIN` and `CC_IAS_CONTROLPLANE_PROD_DEVELOPER`
- [ ] 11.3 Create `remote/custom/components/qa/kustomization.yaml` (kind: Component) that patches group names to `CC_IAS_CONTROLPLANE_QA_ADMIN` and `CC_IAS_CONTROLPLANE_QA_DEVELOPER`
- [ ] 11.4 Update `remote/custom/overlays/rt-eu-de-1/kustomization.yaml` to include `components/prod`
- [ ] 11.5 Verify `kustomize build remote/custom/overlays/rt-eu-de-1/` produces correct prod group names
- [ ] 11.6 Verify that building without a component leaves the invalid placeholder in output
