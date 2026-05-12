## 1. Project scaffolding

- [ ] 1.1 Create directory structure: `system/kustomize/metal-operator-remote/{host/base,host/overlays,remote/upstream/crds-and-rbac,remote/upstream/webhooks/source,remote/custom/base,remote/custom/overlays,components/webhook-injector}`
- [ ] 1.2 Create `remote/upstream/crds-and-rbac/kustomization.yaml` referencing upstream `config/crd` + `config/rbac` at pinned tag with Role→ClusterRole patches
- [ ] 1.3 Create `remote/upstream/webhooks/source/kustomization.yaml` referencing upstream `config/webhook` at pinned tag
- [ ] 1.4 Verify `kustomize build remote/upstream/crds-and-rbac/` succeeds and produces expected CRDs + RBAC

## 2. Webhook URL rendering

- [ ] 2.1 Create `remote/upstream/webhooks/kustomization.yaml` referencing `manifests-url-based.yaml`
- [ ] 2.2 Write the `yq` command to transform service→URL and generate `manifests-url-based.yaml`
- [ ] 2.3 Verify generated webhook manifests match current `metal-operator-remote/webhooks.yaml` content

## 3. Webhook-injector Component

- [ ] 3.1 Create `components/webhook-injector/kustomization.yaml` (kind: Component)
- [ ] 3.2 Create `components/webhook-injector/sidecar.yaml` with full initContainer spec (image, args, ports, probes, resources, volumeMounts)
- [ ] 3.3 Verify Component can be included by a test kustomization and produces correct initContainer in output

## 4. Host base resources

- [ ] 4.1 Create `host/base/kustomization.yaml` referencing upstream `config/manager`, components, patches, and all local resources
- [ ] 4.2 Create `host/base/manager-remote-patch.yaml` (env vars, volumes, pod labels, strategy, serviceAccountName, securityContext)
- [ ] 4.3 Create `host/base/manager-webhook-patch.yaml` (webhook port, certs emptyDir, macdb volume)
- [ ] 4.4 Create local resource files: `webhook-service.yaml`, `metal-registry-service.yaml`, `networkpolicy.yaml`, `webhook-injector-rbac.yaml`
- [ ] 4.5 Create local resource files: `ingress.yaml`, `remote-kubeconfig-configmap.yaml`, `remote-serviceaccount-secret.yaml`, `macdb-secret.yaml`, `rotate-kubeconfig-secret.yaml`, `webhook-config.yaml`
- [ ] 4.6 Verify `kustomize build host/base/` succeeds and produces all expected resource kinds (Deployment, Services, Ingress, NetworkPolicy, ConfigMaps, Secrets, SA, Role, RoleBinding)

## 5. Host overlay example

- [ ] 5.1 Create `host/overlays/rt-eu-de-1/kustomization.yaml` with patches for ingress domain, apiserver URL, macdb, remote CA, image tags, and controller args
- [ ] 5.2 Verify `kustomize build host/overlays/rt-eu-de-1/` succeeds and renders correct environment-specific values

## 6. Remote custom resources

- [ ] 6.1 Create `remote/custom/base/kustomization.yaml` with `namespace.yaml` and `rbac.yaml`
- [ ] 6.2 Create `remote/custom/base/namespace.yaml` (Namespace: metal-servers)
- [ ] 6.3 Create `remote/custom/base/rbac.yaml` with placeholder values for IAS groups and LDAP users
- [ ] 6.4 Create `remote/custom/overlays/rt-eu-de-1/kustomization.yaml` with patches for IAS group names and LDAP admin users
- [ ] 6.5 Verify `kustomize build remote/custom/overlays/rt-eu-de-1/` succeeds

## 7. ManagedResource wrapping

- [ ] 7.1 Write `scripts/wrap-managedresources.sh` that takes multi-document YAML on stdin and produces ManagedResource+Secret pairs
- [ ] 7.2 Generate `remote/upstream/crds-and-rbac/managedresources.yaml` using the script
- [ ] 7.3 Generate `remote/upstream/webhooks/managedresources.yaml` using the script
- [ ] 7.4 Verify generated ManagedResource format matches current `templates/managedresource.yaml` output

## 8. Makefile integration

- [ ] 8.1 Create `system/kustomize/metal-operator-remote/Makefile` with `regen`, `regen-remote-crds`, `regen-remote-webhooks` targets
- [ ] 8.2 Verify `make regen` regenerates all pre-rendered files correctly

## 9. Equivalence verification

- [ ] 9.1 Compare `kustomize build host/overlays/rt-eu-de-1/` output against `helm template metal-operator-remote` with equivalent values — document differences
- [ ] 9.2 Compare `kustomize build remote/upstream/crds-and-rbac/` output against current `managedresources/crds-and-rbac.yaml` — document differences
- [ ] 9.3 Compare webhook output against current `webhooks.yaml` — document differences
- [ ] 9.4 Write findings summary: what works, what doesn't, blockers identified
