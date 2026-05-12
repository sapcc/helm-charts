# Kustomize Metal-Operator-Remote Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `metal-operator-remote` Helm chart with pure kustomize overlays that produce equivalent host/remote resource sets, using upstream `ironcore-dev/metal-operator` `config/` as the base.

**Architecture:** Three-layer structure — `remote/upstream/` (pre-rendered from upstream config/, static for all envs), `remote/custom/` (manually maintained, parameterized per-env), and `host/base+overlays/` (upstream Deployment + local resources, parameterized per-env via overlays). A Makefile regenerates remote upstream resources on version bumps.

**Tech Stack:** kustomize v5+, yq v4+, bash (for wrap-managedresources script), GNU make

---

## Task 1: Project Scaffolding and Remote Upstream CRDs/RBAC

**Files:**
- Create: `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/source/kustomization.yaml`

- [ ] **Step 1: Create the directory structure**

```bash
cd system
mkdir -p kustomize/metal-operator-remote/{host/base,host/overlays,remote/upstream/crds-and-rbac,remote/upstream/webhooks/source,remote/upstream/webhooks,remote/custom/base,remote/custom/overlays,components/webhook-injector,scripts}
```

- [ ] **Step 2: Create remote/upstream/crds-and-rbac/kustomization.yaml**

```yaml
# system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kube-system
resources:
  - https://github.com/ironcore-dev/metal-operator//config/crd?ref=v0.4.0
  - https://github.com/ironcore-dev/metal-operator//config/rbac?ref=v0.4.0
patches:
  - target:
      kind: Role
    patch: |
      - op: replace
        path: /kind
        value: ClusterRole
  - target:
      kind: RoleBinding
    patch: |
      - op: replace
        path: /kind
        value: ClusterRoleBinding
```

- [ ] **Step 3: Create remote/upstream/webhooks/source/kustomization.yaml**

```yaml
# system/kustomize/metal-operator-remote/remote/upstream/webhooks/source/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/ironcore-dev/metal-operator//config/webhook?ref=v0.4.0
```

- [ ] **Step 4: Verify CRDs/RBAC build succeeds**

```bash
cd system/kustomize/metal-operator-remote
kustomize build remote/upstream/crds-and-rbac/ | yq '.kind' | sort | uniq -c
```

Expected: CustomResourceDefinition (16), ClusterRole (many), ClusterRoleBinding (several), ServiceAccount (1). No `Role` or `RoleBinding` in output.

- [ ] **Step 5: Verify webhook source build succeeds**

```bash
kustomize build remote/upstream/webhooks/source/ | yq '.kind' | sort | uniq -c
```

Expected: ValidatingWebhookConfiguration, MutatingWebhookConfiguration (if any), Service.

- [ ] **Step 6: Commit**

```bash
git add system/kustomize/metal-operator-remote/
git commit -m "feat: scaffold kustomize structure and remote upstream overlays"
```

---

## Task 2: Webhook URL Rendering

**Files:**
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml` (generated)

- [ ] **Step 1: Generate manifests-url-based.yaml from upstream webhooks**

```bash
cd system/kustomize/metal-operator-remote
kustomize build remote/upstream/webhooks/source | \
  yq 'select(.kind == "ValidatingWebhookConfiguration" or .kind == "MutatingWebhookConfiguration")' | \
  yq '(.webhooks[].clientConfig | select(.service)) |= {"url": "https://metal-operator-webhook-service:443" + .service.path}' | \
  yq 'del(.webhooks[].clientConfig.service)' \
  > remote/upstream/webhooks/manifests-url-based.yaml
```

- [ ] **Step 2: Create remote/upstream/webhooks/kustomization.yaml**

```yaml
# system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - manifests-url-based.yaml
```

- [ ] **Step 3: Verify webhook output has URL-based clientConfig**

```bash
kustomize build remote/upstream/webhooks/ | yq '.webhooks[0].clientConfig'
```

Expected: `url: https://metal-operator-webhook-service:443/validate-...` with no `service:` field.

- [ ] **Step 4: Compare against current webhooks.yaml**

```bash
diff <(yq 'sort_keys(..)' remote/upstream/webhooks/manifests-url-based.yaml) \
     <(yq 'sort_keys(..)' ../../metal-operator-remote/webhooks.yaml)
```

Document any differences. Labels and metadata may differ (upstream kustomize vs Helm-rendered).

- [ ] **Step 5: Commit**

```bash
git add remote/upstream/webhooks/
git commit -m "feat: generate URL-based webhook manifests from upstream"
```

---

## Task 3: Webhook-Injector Component

**Files:**
- Create: `system/kustomize/metal-operator-remote/components/webhook-injector/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`

- [ ] **Step 1: Create components/webhook-injector/kustomization.yaml**

```yaml
# system/kustomize/metal-operator-remote/components/webhook-injector/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches:
  - path: sidecar.yaml
images:
  - name: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector
    newTag: latest
```

- [ ] **Step 2: Create components/webhook-injector/sidecar.yaml**

```yaml
# system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: controller-manager
spec:
  template:
    spec:
      initContainers:
        - name: webhook-injector
          restartPolicy: Always
          image: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest
          args:
            - --webhook-config-name=webhook-config
            - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
          ports:
            - name: metrics
              containerPort: 8082
            - name: health
              containerPort: 8083
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - "ALL"
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8083
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8083
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          volumeMounts:
            - name: webhook-certs
              mountPath: /tmp/webhook-certs
            - name: remote-serviceaccount
              mountPath: /var/run/secrets/kubernetes.io/remote-serviceaccount
              readOnly: true
            - name: remote-kubeconfig
              mountPath: /var/run/remote-kubeconfig
              readOnly: true
```

- [ ] **Step 3: Create a test kustomization to verify the Component works**

```bash
cd /tmp
mkdir -p test-component && cat > test-component/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/ironcore-dev/metal-operator//config/manager?ref=v0.4.0
components:
  - /path/to/system/kustomize/metal-operator-remote/components/webhook-injector
EOF
kustomize build test-component/ | yq 'select(.kind == "Deployment") | .spec.template.spec.initContainers[0].name'
```

Expected: `webhook-injector`

- [ ] **Step 4: Commit**

```bash
git add components/webhook-injector/
git commit -m "feat: add webhook-injector kustomize Component"
```

---

## Task 4: Host Base Resources

**Files:**
- Create: `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/manager-remote-patch.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/manager-webhook-patch.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/webhook-service.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/metal-registry-service.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/networkpolicy.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/ingress.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/remote-kubeconfig-configmap.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/remote-serviceaccount-secret.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/macdb-secret.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/rotate-kubeconfig-secret.yaml`
- Create: `system/kustomize/metal-operator-remote/host/base/webhook-config.yaml`

- [ ] **Step 1: Create host/base/kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/ironcore-dev/metal-operator//config/manager?ref=v0.4.0
  - webhook-service.yaml
  - metal-registry-service.yaml
  - ingress.yaml
  - networkpolicy.yaml
  - webhook-injector-rbac.yaml
  - webhook-config.yaml
  - remote-kubeconfig-configmap.yaml
  - remote-serviceaccount-secret.yaml
  - macdb-secret.yaml
  - rotate-kubeconfig-secret.yaml
components:
  - ../../components/webhook-injector
patches:
  - target:
      kind: Namespace
    patch: |
      $patch: delete
      apiVersion: v1
      kind: Namespace
      metadata:
        name: system
  - path: manager-remote-patch.yaml
  - path: manager-webhook-patch.yaml
images:
  - name: controller
    newName: ghcr.io/ironcore-dev/metal-operator-controller-manager
    newTag: PLACEHOLDER
```

- [ ] **Step 2: Create host/base/manager-remote-patch.yaml**

Translate the current `values-overrides.yaml` into a strategic merge patch on the upstream Deployment. Include: strategy, env vars, volumes (remote-serviceaccount, remote-kubeconfig), pod labels, serviceAccountName, securityContext, hostNetwork.

Reference: `system/metal-operator-remote/values-overrides.yaml` and `system/metal-operator-remote/values.yaml` for the full set of fields.

- [ ] **Step 3: Create host/base/manager-webhook-patch.yaml**

Add webhook port (9443), webhook-certs emptyDir volume + mount, macdb secret volume + mount.

- [ ] **Step 4: Create static local resources**

Create these files from the current Helm templates, stripping all `{{ }}` references and using placeholder/default values:
- `webhook-service.yaml` — from `templates/webhook-service.yaml`
- `metal-registry-service.yaml` — from `templates/metal-registry-service.yaml`
- `networkpolicy.yaml` — from `templates/networkpolicy.yaml`
- `webhook-injector-rbac.yaml` — from `templates/webhook-injector-rbac.yaml`

- [ ] **Step 5: Create parameterized local resources with placeholders**

Create these files with placeholder values that overlays will patch:
- `ingress.yaml` — placeholder domain `CLUSTER_TYPE.REGION.TLD`
- `remote-kubeconfig-configmap.yaml` — placeholder apiserver URL
- `remote-serviceaccount-secret.yaml` — static (token-requestor labels)
- `macdb-secret.yaml` — empty placeholder
- `rotate-kubeconfig-secret.yaml` — placeholder CA and namespace
- `webhook-config.yaml` — reference to webhooks content (ConfigMap wrapping `manifests-url-based.yaml` content)

- [ ] **Step 6: Verify host base builds**

```bash
kustomize build host/base/
```

Expected: Output contains Deployment, 2 Services, Ingress, NetworkPolicy, 2 ConfigMaps, 3 Secrets, ServiceAccount, Role, RoleBinding. No errors.

- [ ] **Step 7: Verify resource count**

```bash
kustomize build host/base/ | yq '.kind' | sort | uniq -c
```

Expected kinds: ConfigMap(2), Deployment(1), Ingress(1), NetworkPolicy(1), Role(1), RoleBinding(1), Secret(3), Service(2), ServiceAccount(1).

- [ ] **Step 8: Commit**

```bash
git add host/base/
git commit -m "feat: add host base resources with upstream Deployment patches"
```

---

## Task 5: Host Overlay Example (rt-eu-de-1)

**Files:**
- Create: `system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1/kustomization.yaml`

- [ ] **Step 1: Create host/overlays/rt-eu-de-1/kustomization.yaml**

Include patches for: ingress domain, remote-kubeconfig apiserver URL, macdb content, rotate-kubeconfig CA, Deployment args, image tags. Use the `examples/host/overlays/rt-eu-de-1/kustomization.yaml` from the openspec artifacts as reference.

- [ ] **Step 2: Verify overlay builds successfully**

```bash
kustomize build host/overlays/rt-eu-de-1/
```

Expected: All resources rendered with rt-eu-de-1 specific values. No placeholder strings remaining.

- [ ] **Step 3: Spot-check specific values**

```bash
kustomize build host/overlays/rt-eu-de-1/ | yq 'select(.kind == "Ingress") | .spec.rules[0].host'
```

Expected: `metal-operator-remote.runtime.eu-de-1.cloud.sap`

```bash
kustomize build host/overlays/rt-eu-de-1/ | yq 'select(.kind == "Deployment") | .spec.template.spec.containers[0].image'
```

Expected: `ghcr.io/ironcore-dev/metal-operator-controller-manager:sha-4854c23`

- [ ] **Step 4: Commit**

```bash
git add host/overlays/
git commit -m "feat: add rt-eu-de-1 host overlay with environment values"
```

---

## Task 6: Remote Custom Resources

**Files:**
- Create: `system/kustomize/metal-operator-remote/remote/custom/base/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/custom/base/namespace.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/custom/base/rbac.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1/kustomization.yaml`

- [ ] **Step 1: Create remote/custom/base/namespace.yaml**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: metal-servers
```

- [ ] **Step 2: Create remote/custom/base/rbac.yaml**

Copy from `system/metal-operator-remote/managedresources/rbac.yaml`, replacing Helm template expressions with placeholder values:
- `{{ if contains "qa-de-" .Values.global.region }}...{{ else }}...{{ end }}` → use prod group names as default
- `{{ .Values.adminLDAPUsers }}` → empty list or placeholder

- [ ] **Step 3: Create remote/custom/base/kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - rbac.yaml
```

- [ ] **Step 4: Create remote/custom/overlays/rt-eu-de-1/kustomization.yaml**

Patch IAS group names and LDAP users for the rt-eu-de-1 environment (prod groups).

- [ ] **Step 5: Verify custom remote overlay builds**

```bash
kustomize build remote/custom/overlays/rt-eu-de-1/ | yq '.kind' | sort | uniq -c
```

Expected: ClusterRole, ClusterRoleBinding, Namespace, Role, RoleBinding, ServiceAccount.

- [ ] **Step 6: Commit**

```bash
git add remote/custom/
git commit -m "feat: add remote custom resources with per-env RBAC overlays"
```

---

## Task 7: ManagedResource Wrapping Script

**Files:**
- Create: `system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh`

- [ ] **Step 1: Write scripts/wrap-managedresources.sh**

The script reads multi-document YAML from stdin, and for each document produces a ManagedResource + Secret pair. Logic matches `system/metal-operator-remote/templates/managedresource.yaml`:
- Name: `mr-<KIND_INITIALS_LOWERCASE>-<resource-name-sanitized>`
- Secret contains `data.objects.yaml` with base64-encoded resource

```bash
#!/bin/bash
# Reads multi-document YAML from stdin
# Produces ManagedResource+Secret pairs on stdout
set -euo pipefail

while IFS= read -r -d '' doc; do
  [ -z "$doc" ] && continue
  kind=$(echo "$doc" | yq '.kind')
  name=$(echo "$doc" | yq '.metadata.name' | tr '.:' '-')
  prefix=$(echo "$kind" | grep -oE '[A-Z]' | tr '[:upper:]' '[:lower:]' | tr -d '\n')
  mrname="mr-${prefix}-${name}"
  encoded=$(echo "$doc" | base64 | tr -d '\n')
  
  cat <<EOF
---
apiVersion: resources.gardener.cloud/v1alpha1
kind: ManagedResource
metadata:
  name: ${mrname}
spec:
  secretRefs:
  - name: ${mrname}
---
apiVersion: v1
kind: Secret
metadata:
  name: ${mrname}
type: Opaque
data:
  objects.yaml: ${encoded}
EOF
done < <(yq -r -s '.' | sed 's/^---$/\x00/g' | tr '\0' '\n'... )
```

Note: The exact implementation will need testing — `yq` document splitting in bash requires care. Use `yq eval-all 'select(. != null)' | ...` or split on `---`.

- [ ] **Step 2: Make the script executable and test it**

```bash
chmod +x scripts/wrap-managedresources.sh
echo '---
apiVersion: v1
kind: Namespace
metadata:
  name: test-ns' | ./scripts/wrap-managedresources.sh
```

Expected: One ManagedResource named `mr-n-test-ns` + one Secret with base64 content.

- [ ] **Step 3: Compare wrapping output format against current chart**

```bash
helm template metal-operator-remote ../../metal-operator-remote/ | yq 'select(.kind == "ManagedResource")' | head -20
```

Compare naming convention and structure with script output.

- [ ] **Step 4: Commit**

```bash
git add scripts/
git commit -m "feat: add wrap-managedresources.sh for ManagedResource generation"
```

---

## Task 8: Makefile and Pre-rendering

**Files:**
- Create: `system/kustomize/metal-operator-remote/Makefile`

- [ ] **Step 1: Create the Makefile**

```makefile
# system/kustomize/metal-operator-remote/Makefile
.PHONY: regen regen-remote-crds regen-remote-webhooks

regen: regen-remote-crds regen-remote-webhooks

regen-remote-crds:
	@kustomize build remote/upstream/crds-and-rbac | \
		./scripts/wrap-managedresources.sh > remote/upstream/crds-and-rbac/managedresources.yaml
	@echo "Generated remote/upstream/crds-and-rbac/managedresources.yaml"

regen-remote-webhooks:
	@kustomize build remote/upstream/webhooks/source | \
		yq 'select(.kind == "ValidatingWebhookConfiguration" or .kind == "MutatingWebhookConfiguration")' | \
		yq '(.webhooks[].clientConfig | select(.service)) |= {"url": "https://metal-operator-webhook-service:443" + .service.path}' | \
		yq 'del(.webhooks[].clientConfig.service)' \
		> remote/upstream/webhooks/manifests-url-based.yaml
	@kustomize build remote/upstream/webhooks | \
		./scripts/wrap-managedresources.sh > remote/upstream/webhooks/managedresources.yaml
	@echo "Generated remote/upstream/webhooks/manifests-url-based.yaml"
	@echo "Generated remote/upstream/webhooks/managedresources.yaml"
```

- [ ] **Step 2: Run make regen and verify output**

```bash
make regen
ls -la remote/upstream/crds-and-rbac/managedresources.yaml
ls -la remote/upstream/webhooks/managedresources.yaml
ls -la remote/upstream/webhooks/manifests-url-based.yaml
```

All three files should exist and contain valid YAML.

- [ ] **Step 3: Verify managedresources.yaml is valid**

```bash
yq '.kind' remote/upstream/crds-and-rbac/managedresources.yaml | sort | uniq -c
```

Expected: ManagedResource (N), Secret (N) — one pair per upstream resource.

- [ ] **Step 4: Commit**

```bash
git add Makefile remote/upstream/*/managedresources.yaml remote/upstream/webhooks/manifests-url-based.yaml
git commit -m "feat: add Makefile and generate pre-rendered ManagedResources"
```

---

## Task 9: Equivalence Verification

**Files:**
- Create: `system/kustomize/metal-operator-remote/VERIFICATION.md` (findings document)

- [ ] **Step 1: Compare remote CRDs/RBAC**

```bash
diff <(kustomize build remote/upstream/crds-and-rbac/ | yq -s 'sort_keys(..) | .kind + "/" + .metadata.name' | sort) \
     <(yq -s 'sort_keys(..) | .kind + "/" + .metadata.name' ../../metal-operator-remote/managedresources/crds-and-rbac.yaml | sort)
```

Document: resource count, any missing/extra resources, label differences.

- [ ] **Step 2: Compare webhooks**

```bash
diff <(yq 'sort_keys(..)' remote/upstream/webhooks/manifests-url-based.yaml) \
     <(yq 'sort_keys(..) | select(.kind != "ConfigMap")' ../../metal-operator-remote/webhooks.yaml)
```

Document: URL format differences, metadata differences.

- [ ] **Step 3: Compare host Deployment**

```bash
kustomize build host/overlays/rt-eu-de-1/ | yq 'select(.kind == "Deployment") | sort_keys(..)' > /tmp/kustomize-deployment.yaml
# Compare against helm template output (need equivalent values)
```

Document: structural differences, any features not expressible in kustomize.

- [ ] **Step 4: Write VERIFICATION.md with findings**

Summarize: what matches, what differs (and why — e.g., Helm labels vs kustomize labels), any blockers, recommendation.

- [ ] **Step 5: Commit**

```bash
git add VERIFICATION.md
git commit -m "docs: add equivalence verification findings"
```

---

## Task 10: Documentation

**Files:**
- Create: `system/kustomize/metal-operator-remote/README.md`

- [ ] **Step 1: Create README.md**

Use the operator guide from `openspec/changes/poc-kustomize-metal-operator-remote/examples/README.md` as the source. Adapt paths to final structure.

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add operator guide for kustomize metal-operator-remote"
```
