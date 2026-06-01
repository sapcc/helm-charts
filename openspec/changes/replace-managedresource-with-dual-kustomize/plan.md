# replace-managedresource-with-dual-kustomize Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the `metal-operator-remote` kustomize tree to drop `ManagedResource` delivery, eliminate Makefile pre-rendering, and implement the dual-kustomize + ExternalName-routing webhook delivery model defined in `specs/`. After this plan executes, `kustomize build host/base/` and `kustomize build remote/` produce plain Kubernetes manifests applicable directly via `kubectl apply -k` (no MR wrapping, no caBundle field, no URL rewrite, no regen cycle).

**Architecture:** Dual kustomize roots (`host/`, `remote/`) consumed by `cc/kube-secrets` per-cluster overlays via Git URL ref. `remote/upstream/webhooks/` becomes a two-layer structure (`upstream-no-svc/` inner removes upstream's regular Service via `$patch: delete`; outer adds `system` Namespace + `webhook-service` ExternalName Service). `host/base/manager-patch.yaml` consolidates all controller-manager Deployment customizations including the 6 SAP-specific args missed by the kustomize POC. The webhook-injector sidecar narrows to caBundle-rotation mode (out-of-repo binary change tracked at `SAP-cloud-infrastructure/webhook-injector#9`).

**Tech Stack:** kustomize v5+, kubectl, Make, yq, git. No Go/Python code is written; this is a YAML/Makefile restructure.

---

## Task 1: Pre-flight checks (coordination, no code changes)

**Files:**
- Read: `openspec/changes/replace-managedresource-with-dual-kustomize/specs/*/spec.md`
- Read: `openspec/changes/replace-managedresource-with-dual-kustomize/design.md`

- [ ] **Step 1.1: Verify webhook-injector#9 status**

  Run: `gh issue view 9 --repo SAP-cloud-infrastructure/webhook-injector --json state,labels,assignees,milestone`
  Expected: shows current state of the issue. If "open" and unassigned, the production-cutover gate (Task 13) will be blocked but this plan can still complete and the PR can land in master.

- [ ] **Step 1.2: Confirm `cc/kube-secrets` PR #3905 status**

  Run: `gh pr view 3905 --repo cc/kube-secrets --json state,title,mergeable`
  Expected: shows draft state. Confirm the prior `move-cluster-overlays-to-kube-secrets` companion PR is the predecessor; the kube-secrets-side counterpart for THIS change exists at `/Users/D065300/IdeaProjects/sapcc/kube-secrets` on branch `openspec/replace-managedresource-with-dual-kustomize`.

- [ ] **Step 1.3: Verify webhook-injector is in production for metal-operator-remote**

  Inspect a sample production cluster (rt-eu-de-1 or a-qa-de-200): does the controller pod have a `webhook-injector` initContainer? If unsure, ask the operator or check the helm-rendered Deployment from the seed namespace.
  Expected: yes — `_webhook-injector-sidecar.tpl` is included in `templates/controller-manager.yaml` and the helm chart deploys it. No legacy non-sidecar path exists.

- [ ] **Step 1.4: Audit kustomize tree for any other GRM-era patches**

  Run from repo root:
  ```bash
  grep -rE "ManagedResource|wrap-managedresources|managedresources\.yaml" system/kustomize/metal-operator-remote/ --include="*.yaml" --include="*.sh" | grep -v "/source/"
  ```
  Expected: matches in `remote/upstream/{crds-and-rbac,webhooks}/kustomization.yaml`, `remote/upstream/{crds-and-rbac,webhooks}/managedresources.yaml`, `scripts/wrap-managedresources.sh`, `host/base/kustomization.yaml` references (if any). All these will be addressed in subsequent tasks. Note any MR-related references NOT in those files for the implementation phase.

---

## Task 2: Webhook delivery restructure (two-layer kustomize)

**Files:**
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/kustomization.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/system-namespace.yaml`
- Create: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/webhook-service-stub.yaml`
- Modify: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`
- Delete: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml`
- Delete: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml`
- Delete: `system/kustomize/metal-operator-remote/remote/upstream/webhooks/source/` (subdirectory — its contents move into the new `upstream-no-svc/` inner layer)

- [ ] **Step 2.1: Capture current webhook build output as baseline**

  Run from repo root:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/webhooks/ | yq '.kind' | sort | uniq -c > /tmp/webhooks-before.txt
  cat /tmp/webhooks-before.txt
  ```
  Expected output (current state, MR-wrapped):
  ```
        1 ManagedResource
        1 Secret
  ```

- [ ] **Step 2.2: Create the inner-layer subdirectory**

  Run: `mkdir -p system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc`

- [ ] **Step 2.3: Write the inner-layer kustomization.yaml**

  Create `system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/kustomization.yaml` with content:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  # Inner layer: pulls upstream's config/webhook directory (which contains
  # manifests.yaml + service.yaml) and removes the regular ClusterIP Service.
  # The outer layer at ../kustomization.yaml adds the `system` Namespace
  # and the webhook-service ExternalName Service.
  resources:
    - https://github.com/ironcore-dev/metal-operator//config/webhook?ref=v0.4.0
  patches:
    # Remove upstream's regular ClusterIP Service. The workerless cluster
    # uses an ExternalName Service (added by the outer layer) to bridge
    # webhook callbacks to the host cluster's actual webhook service.
    - target:
        kind: Service
        name: webhook-service
        namespace: system
      patch: |
        $patch: delete
        apiVersion: v1
        kind: Service
        metadata:
          name: webhook-service
          namespace: system
  ```

- [ ] **Step 2.4: Verify inner-layer build produces only the webhook config**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/webhooks/upstream-no-svc/ | yq '.kind' | sort | uniq -c
  ```
  Expected output:
  ```
        1 ValidatingWebhookConfiguration
  ```

- [ ] **Step 2.5: Create system-namespace.yaml**

  Create `system/kustomize/metal-operator-remote/remote/upstream/webhooks/system-namespace.yaml` with content:
  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: system
  ```

- [ ] **Step 2.6: Create webhook-service-stub.yaml**

  Create `system/kustomize/metal-operator-remote/remote/upstream/webhooks/webhook-service-stub.yaml` with content:
  ```yaml
  # ExternalName Service in the workerless cluster's `system` namespace.
  # When the workerless API server resolves clientConfig.service:
  #   { name: webhook-service, namespace: system }
  # it finds this ExternalName Service, reads the externalName field, and
  # resolves "metal-operator-webhook-service" via the API server pod's
  # /etc/resolv.conf search paths to the host cluster's actual Service.
  # The short name (no namespace suffix) is identical for all clusters —
  # mirrors today's pre-rendered URL "https://metal-operator-webhook-service:443/...".
  apiVersion: v1
  kind: Service
  metadata:
    name: webhook-service
    namespace: system
  spec:
    type: ExternalName
    externalName: metal-operator-webhook-service
  ```

- [ ] **Step 2.7: Rewrite the outer kustomization.yaml**

  Replace `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml` with:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  # Outer layer: composes the inner upstream-no-svc/ output (the
  # ValidatingWebhookConfiguration with upstream's regular Service removed)
  # plus the `system` Namespace and our ExternalName Service stub.
  # Applied directly to the workerless cluster via `kubectl apply -k remote/`.
  resources:
    - upstream-no-svc/
    - system-namespace.yaml
    - webhook-service-stub.yaml
  ```

- [ ] **Step 2.8: Delete the obsolete pre-rendered files and source/ subdir**

  Run:
  ```bash
  rm system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml
  rm system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml
  rm -rf system/kustomize/metal-operator-remote/remote/upstream/webhooks/source
  ```

- [ ] **Step 2.9: Verify outer-layer build produces expected three resources**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/webhooks/ | yq '.kind' | sort | uniq -c
  ```
  Expected output (no MR, no Secret-wrapping; three plain resources):
  ```
        1 Namespace
        1 Service
        1 ValidatingWebhookConfiguration
  ```

- [ ] **Step 2.10: Verify the caBundle invariant (kustomize tree must not emit caBundle)**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/webhooks/ | yq '.. | select(has("caBundle"))? // "missing"' | grep -v "^missing$" | grep -v "^---$"
  ```
  Expected output: empty (no `caBundle` field in any rendered resource).

- [ ] **Step 2.11: Verify ExternalName Service shape**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/webhooks/ | yq 'select(.kind == "Service" and .metadata.namespace == "system") | {type: .spec.type, externalName: .spec.externalName}'
  ```
  Expected output:
  ```yaml
  type: ExternalName
  externalName: metal-operator-webhook-service
  ```

- [ ] **Step 2.12: Commit**

  ```bash
  git add system/kustomize/metal-operator-remote/remote/upstream/webhooks/
  git commit -m "feat(metal-operator-remote): two-layer webhook delivery with ExternalName routing

Replace pre-rendered ManagedResource webhook delivery with a two-layer kustomize
structure that (a) pulls upstream's webhook config directly via Git URL ref,
(b) removes upstream's regular ClusterIP Service via \$patch: delete in an inner
layer, and (c) adds a workerless-cluster system Namespace + webhook-service
ExternalName Service in the outer layer. The ExternalName bridges
clientConfig.service callbacks from the workerless API server to the host
cluster's actual metal-operator-webhook-service via /etc/resolv.conf search
paths — same DNS-search-path mechanism today's pre-rendered URL relies on.

No URL rewrite, no pre-rendered file, no Makefile target. Upstream version bumps
propagate by editing ?ref=<tag> in upstream-no-svc/kustomization.yaml.

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 3: Remote root composition

**Files:**
- Create: `system/kustomize/metal-operator-remote/remote/kustomization.yaml`
- Modify: `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml`
- Delete: `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml`
- Delete: `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/source/` (subdirectory — its content folds into the parent `kustomization.yaml`)

- [ ] **Step 3.1: Capture current crds-and-rbac build output as baseline**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/crds-and-rbac/ | yq '.kind' | sort | uniq -c > /tmp/crds-rbac-before.txt
  cat /tmp/crds-rbac-before.txt
  ```
  Expected (current state, MR-wrapped):
  ```
        1 ManagedResource
        1 Secret
  ```

- [ ] **Step 3.2: Replace crds-and-rbac/kustomization.yaml with Git URL ref + Service exclusion only**

  Replace `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml` with:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  # Direct apply to the workerless cluster (no ManagedResource wrapping).
  # Upstream RBAC applied verbatim: Roles stay Roles, RoleBindings stay
  # RoleBindings — the Role→ClusterRole conversion was a GRM-era workaround
  # that the helm chart's bundled managedresources/crds-and-rbac.yaml proves
  # un-converted Roles work in production.
  namespace: kube-system
  resources:
    - https://github.com/ironcore-dev/metal-operator//config/crd?ref=v0.4.0
    - https://github.com/ironcore-dev/metal-operator//config/rbac?ref=v0.4.0
  patches:
    # Exclude the metrics Service from upstream config/rbac/. The workerless
    # cluster has no kube-proxy and no metrics scraping; this Service has no
    # use there.
    - target:
        kind: Service
      patch: |
        $patch: delete
        apiVersion: v1
        kind: Service
        metadata:
          name: $any
  ```

- [ ] **Step 3.3: Delete the obsolete managedresources.yaml and source/ subdir**

  Run:
  ```bash
  rm system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml
  rm -rf system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/source
  ```

- [ ] **Step 3.4: Verify crds-and-rbac build output (no MR, Roles preserved)**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/crds-and-rbac/ | yq '.kind' | sort | uniq -c
  ```
  Expected output (matching the helm chart's bundled managedresources/crds-and-rbac.yaml: 16 CRDs + 55 ClusterRoles + 10 ClusterRoleBindings + 2 ServiceAccounts + 1 Role + 1 RoleBinding):
  ```
       55 ClusterRole
       10 ClusterRoleBinding
       16 CustomResourceDefinition
        1 Role
        1 RoleBinding
        2 ServiceAccount
  ```

- [ ] **Step 3.5: Verify NO Service from upstream metrics**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/upstream/crds-and-rbac/ | yq 'select(.kind == "Service")'
  ```
  Expected output: empty.

- [ ] **Step 3.6: Create the top-level remote/ kustomization composing all subpaths**

  Create `system/kustomize/metal-operator-remote/remote/kustomization.yaml` with content:
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  # Top-level remote/ kustomize root: applied directly to the workerless cluster
  # via `kubectl apply -k remote/` (typically through a kube-secrets per-cluster
  # overlay's `remote/` subpath that references this tree as a base).
  #
  # Composes:
  #   - upstream/crds-and-rbac/  : CRDs + ClusterRoles + ClusterRoleBindings + ServiceAccount
  #                                (un-converted Roles/RoleBindings preserved)
  #   - upstream/webhooks/       : ValidatingWebhookConfiguration + system Namespace
  #                                + webhook-service ExternalName Service
  #   - custom/                  : custom Namespace (metal-servers) + custom RBAC
  #                                (OIDC ClusterRoleBindings + metal-token-rotate)
  #
  # NO ManagedResource. NO caBundle field anywhere. Upstream consumed live
  # via Git URL ref (no committed pre-renders).
  resources:
    - upstream/crds-and-rbac
    - upstream/webhooks
    - custom
  ```

- [ ] **Step 3.7: Verify full remote build output**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/ | yq '.kind' | sort | uniq -c
  ```
  Expected output (CRDs+RBAC+ServiceAccount + system Namespace + ExternalName Service + ValidatingWebhookConfiguration + custom Namespace + custom RBAC):
  ```
       55 ClusterRole
       11 ClusterRoleBinding   # 10 from upstream + 1 from custom
       16 CustomResourceDefinition
        1 Role
        1 RoleBinding
        2 Namespace            # metal-servers + system
        1 Service              # webhook-service ExternalName
        2 ServiceAccount       # 1 from upstream + 1 metal-token-rotate
        1 ValidatingWebhookConfiguration
  ```
  (Counts may vary by ±1 if the custom RBAC includes additional ClusterRoles. Confirm against `helm template`-rendered managedresources/crds-and-rbac.yaml + rbac.yaml + webhooks.yaml.)

- [ ] **Step 3.8: Verify NO ManagedResource in full remote output**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/ | yq '.kind' | grep -c ManagedResource
  ```
  Expected output: `0`.

- [ ] **Step 3.9: Verify NO caBundle field in full remote output**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build remote/ | yq '.. | select(has("caBundle"))? // "missing"' | grep -v "^missing$" | grep -v "^---$"
  ```
  Expected output: empty.

- [ ] **Step 3.10: Commit**

  ```bash
  git add system/kustomize/metal-operator-remote/remote/
  git commit -m "feat(metal-operator-remote): direct-apply remote root via Git URL refs

Replace ManagedResource pipeline with direct kubectl apply -k for workerless
cluster resources. The new remote/kustomization.yaml composes upstream
crds-and-rbac, webhooks, and custom RBAC into a single self-contained
kustomize root.

Drop the GRM-era Role→ClusterRole conversion in upstream/crds-and-rbac/
— upstream Roles are applied verbatim (matching the helm chart's existing
bundled managedresources/crds-and-rbac.yaml behavior, which has been in
production untouched). Drop the pre-rendered managedresources.yaml file
and the source/ subdirectory; consume upstream live via Git URL ref.

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 4: Host root — consolidate manager patches and restore SAP args

**Files:**
- Create: `system/kustomize/metal-operator-remote/host/base/manager-patch.yaml`
- Modify: `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`
- Delete: `system/kustomize/metal-operator-remote/host/base/manager-remote-patch.yaml`
- Delete: `system/kustomize/metal-operator-remote/host/base/manager-webhook-patch.yaml`

- [ ] **Step 4.1: Capture current host base build output as baseline**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ > /tmp/host-base-before.yaml
  yq 'select(.kind == "Deployment") | .spec.template.spec.containers[0].args' /tmp/host-base-before.yaml
  ```
  Expected output: `--leader-elect` only (the SAP-specific args are missing in the current kustomize tree).

- [ ] **Step 4.2: Create the consolidated manager-patch.yaml**

  Create `system/kustomize/metal-operator-remote/host/base/manager-patch.yaml` with content:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: controller-manager
    namespace: system
  spec:
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          networking.gardener.cloud/to-dns: allowed
          networking.gardener.cloud/to-private-networks: allowed
          networking.gardener.cloud/to-public-networks: allowed
          networking.gardener.cloud/to-runtime-apiserver: allowed
          networking.resources.gardener.cloud/to-all-istio-ingresses-istio-ingressgateway-tcp-9443: allowed
          networking.resources.gardener.cloud/to-kube-apiserver-tcp-443: allowed
      spec:
        serviceAccountName: metal-operator-webhook-injector
        hostNetwork: false
        securityContext:
          runAsNonRoot: true
          seccompProfile:
            type: RuntimeDefault
          runAsUser: 65532
          runAsGroup: 65532
        containers:
          - name: manager
            args:
              - --mac-prefixes-file=/etc/macdb/macdb.yaml
              - --probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:latest
              - --probe-os-image=ghcr.io/ironcore-dev/os-images/gardenlinux:1443.3
              - --insecure=false
              - --registry-url=http://[2a10:afc0:e013:d002::]:30010
              - --manager-namespace=metal-operator-system
            env:
              - name: KUBERNETES_SERVICE_HOST
                value: "APISERVER_URL_PLACEHOLDER"
              - name: KUBERNETES_CLUSTER_DOMAIN
                value: "cluster.local"
              - name: KUBECONFIG
                value: "/var/run/remote-kubeconfig/kubeconfig"
            ports:
              - containerPort: 9443
                name: webhook-server
                protocol: TCP
            resources:
              limits:
                cpu: "5"
                memory: 5Gi
              requests:
                cpu: 300m
                memory: 50Mi
            volumeMounts:
              - name: webhook-certs
                mountPath: /tmp/k8s-webhook-server/serving-certs
                readOnly: true
              - name: macdb
                mountPath: /etc/macdb
              - name: remote-serviceaccount
                mountPath: /var/run/secrets/kubernetes.io/remote-serviceaccount
                readOnly: true
              - name: remote-kubeconfig
                mountPath: /var/run/remote-kubeconfig
                readOnly: true
        volumes:
          - name: webhook-certs
            emptyDir: {}
          - name: macdb
            secret:
              secretName: macdb
          - name: remote-serviceaccount
            secret:
              secretName: metal-operator-remote-kubeconfig
              items:
                - key: token
                  path: token
                - key: bundle.crt
                  path: ca.crt
          - name: remote-kubeconfig
            configMap:
              name: remote-kubeconfig
  ```

- [ ] **Step 4.3: Delete the old split patch files**

  Run:
  ```bash
  rm system/kustomize/metal-operator-remote/host/base/manager-remote-patch.yaml
  rm system/kustomize/metal-operator-remote/host/base/manager-webhook-patch.yaml
  ```

- [ ] **Step 4.4: Update host/base/kustomization.yaml's patches list**

  Read `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`. Replace the existing two `- path:` entries for `manager-remote-patch.yaml` and `manager-webhook-patch.yaml` with a single `- path: manager-patch.yaml` entry. The Namespace-delete patch (the first patch) stays unchanged. After edit, the relevant patches block should look like:
  ```yaml
  patches:
    # Remove the Namespace resource from upstream config/manager
    - target:
        kind: Namespace
      patch: |
        $patch: delete
        apiVersion: v1
        kind: Namespace
        metadata:
          name: system
    # Consolidated controller-manager Deployment customizations
    # (env vars, args, volumes, ports, securityContext, network labels, etc.)
    - path: manager-patch.yaml
  ```

- [ ] **Step 4.5: Verify host base build output contains the SAP args**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ | yq 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "manager") | .args'
  ```
  Expected output (the 6 SAP args; `--leader-elect` is replaced because strategic merge replaces primitive arrays):
  ```yaml
  - --mac-prefixes-file=/etc/macdb/macdb.yaml
  - --probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:latest
  - --probe-os-image=ghcr.io/ironcore-dev/os-images/gardenlinux:1443.3
  - --insecure=false
  - --registry-url=http://[2a10:afc0:e013:d002::]:30010
  - --manager-namespace=metal-operator-system
  ```

- [ ] **Step 4.6: Verify host base build output contains all expected resources except `webhook-config` ConfigMap (which we'll delete next task)**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ | yq '.kind' | sort | uniq -c
  ```
  Expected output:
  ```
        1 ConfigMap          # remote-kubeconfig (webhook-config still here pending Task 6)
        1 ConfigMap          # webhook-config — will be deleted in Task 6
        1 Deployment
        1 Ingress
        5 NetworkPolicy
        1 Role
        1 RoleBinding
        3 Secret
        2 Service
        1 ServiceAccount
  ```
  Note: `webhook-config` ConfigMap removal happens in Task 6 (delete obsolete pre-render machinery).

- [ ] **Step 4.7: Commit**

  ```bash
  git add system/kustomize/metal-operator-remote/host/base/
  git commit -m "feat(metal-operator-remote): consolidate manager patches + restore SAP args

Replace the split manager-remote-patch.yaml and manager-webhook-patch.yaml
with a single host/base/manager-patch.yaml containing all controller-manager
Deployment customizations. The previous split mixed webhook concerns with
the macdb volume (which has nothing to do with webhooks); consolidating
removes that ambiguity and gives reviewers one place to see all manager
customizations.

Restore the 6 SAP-specific manager args that were missing from the kustomize
tree (POC stage). The kustomize-deployed Deployment will now have:
  --mac-prefixes-file=/etc/macdb/macdb.yaml
  --probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:latest
  --probe-os-image=ghcr.io/ironcore-dev/os-images/gardenlinux:1443.3
  --insecure=false
  --registry-url=http://[2a10:afc0:e013:d002::]:30010
  --manager-namespace=metal-operator-system

Matches the helm chart's values-overrides.yaml; closes the deploy-readiness
gap where the kustomize-rendered controller would have only --leader-elect
from upstream config/manager.

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 5: Webhook-injector sidecar configuration for caBundle-rotation mode

**Files:**
- Modify: `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`
- Modify: `system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml`

- [ ] **Step 5.1: Capture current sidecar args as baseline**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  yq 'select(.kind == "Deployment") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .args' components/webhook-injector/sidecar.yaml
  ```
  Expected output (current):
  ```yaml
  - --webhook-config-name=webhook-config
  - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
  ```

- [ ] **Step 5.2: Edit the sidecar to add WEBHOOK_INJECTOR_MODE env var and update --webhook-config-name**

  Edit `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`. Find the `args:` block (under `initContainers[name=webhook-injector]`) and replace it. Also add an `env:` block. The relevant section should look like:
  ```yaml
        initContainers:
          - name: webhook-injector
            restartPolicy: Always
            image: keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest
            # caBundle-rotation mode: the sidecar reads the existing workerless
            # ValidatingWebhookConfiguration (named below) and patches its
            # caBundle field. Does NOT read a local webhook-config ConfigMap;
            # does NOT push the WebhookConfiguration content (the workerless
            # remote/ kustomize root delivers the WebhookConfiguration directly).
            #
            # Tracked in SAP-cloud-infrastructure/webhook-injector#9 — the
            # binary must support this mode before production cutover.
            env:
              - name: WEBHOOK_INJECTOR_MODE
                value: ca-rotation
            args:
              # In ca-rotation mode, --webhook-config-name names the workerless
              # ValidatingWebhookConfiguration to patch caBundle into (NOT a
              # local ConfigMap on host). "validating-webhook-configuration" is
              # the name from upstream's config/webhook/manifests.yaml.
              - --webhook-config-name=validating-webhook-configuration
              - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
  ```
  (Other fields — `ports`, `securityContext`, `resources`, probes, `volumeMounts` — stay unchanged.)

- [ ] **Step 5.3: Verify sidecar args + env in host build output**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ | yq 'select(.kind == "Deployment") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | {env: .env, args: .args}'
  ```
  Expected output:
  ```yaml
  env:
    - name: WEBHOOK_INJECTOR_MODE
      value: ca-rotation
  args:
    - --webhook-config-name=validating-webhook-configuration
    - --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig
  ```

- [ ] **Step 5.4: Narrow the host-side webhook-injector RBAC**

  Edit `system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml`. The current Role grants `get,list,watch` on `configmaps` and `get,list,watch,create,update,patch` on `secrets`. In ca-rotation mode the sidecar:
  - Does NOT need ConfigMap access (the local `webhook-config` ConfigMap is gone)
  - Still needs Secret access for the TLS cert it manages
  - Still needs `events` and `leases` for standard controller-runtime behavior

  Replace the Role definition with:
  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: metal-operator-webhook-injector
  rules:
    # NOTE: in ca-rotation mode the sidecar does NOT read a local webhook-config
    # ConfigMap. ConfigMap access has been removed from this Role.
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["create", "patch", "update"]
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get", "list", "watch", "create", "update", "patch"]
    - apiGroups: ["coordination.k8s.io"]
      resources: ["leases"]
      verbs: ["get", "create", "update"]
  ```

- [ ] **Step 5.5: Verify the narrowed host-side RBAC**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ | yq 'select(.kind == "Role" and .metadata.name == "metal-operator-webhook-injector") | .rules'
  ```
  Expected output: rules for `events`, `secrets`, `leases` only — NO `configmaps` rule.

- [ ] **Step 5.6: Commit**

  ```bash
  git add system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml \
          system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml
  git commit -m "feat(metal-operator-remote): narrow webhook-injector to caBundle-rotation mode

Configure the webhook-injector sidecar to run in caBundle-rotation mode:
  WEBHOOK_INJECTOR_MODE=ca-rotation env var
  --webhook-config-name=validating-webhook-configuration (the workerless resource)
  (--target-kubeconfig unchanged — still points at remote-kubeconfig mount)

In this mode the sidecar (a) does NOT read a local webhook-config ConfigMap
on host (the workerless remote/ kustomize root is the source-of-truth), and
(b) only patches the caBundle field of the named workerless ValidatingWebhook
Configuration via remote-kubeconfig — does NOT create or replace the resource.

Narrow the host-side Role: drop ConfigMap access (no longer needed), keep
events/secrets/leases for standard controller-runtime behavior. The remote-
side ClusterRole (delivered via remote-kubeconfig) is the responsibility of
the workerless cluster setup; verify it's scoped to get+patch on
validatingwebhookconfigurations only.

Tracking: cc/unified-kubernetes#831, webhook-injector#9"
  ```

---

## Task 6: Delete obsolete pre-render machinery

**Files:**
- Delete: `system/kustomize/metal-operator-remote/host/base/webhook-config.yaml`
- Delete: `system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh`
- Delete: `system/kustomize/metal-operator-remote/scripts/` (directory becomes empty)
- Modify: `system/Makefile`
- Modify: `system/kustomize/metal-operator-remote/host/base/kustomization.yaml` (remove webhook-config.yaml from resources)
- Modify or audit: `system/kustomize/metal-operator-remote/VERIFICATION.md` (out of scope per Open Question)

- [ ] **Step 6.1: Delete the host-side webhook-config ConfigMap**

  Run:
  ```bash
  rm system/kustomize/metal-operator-remote/host/base/webhook-config.yaml
  ```

- [ ] **Step 6.2: Remove webhook-config.yaml from the host base kustomization resources list**

  Edit `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`. Remove the line `- webhook-config.yaml` from the `resources:` block. Save.

- [ ] **Step 6.3: Verify webhook-config ConfigMap absent from host build output**

  Run:
  ```bash
  cd system/kustomize/metal-operator-remote
  kustomize build host/base/ | yq 'select(.kind == "ConfigMap" and .metadata.name == "webhook-config")'
  ```
  Expected output: empty.

- [ ] **Step 6.4: Delete the wrap-managedresources.sh script and its directory**

  Run:
  ```bash
  rm system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh
  # If scripts/ is now empty, remove it:
  rmdir system/kustomize/metal-operator-remote/scripts/ 2>/dev/null || ls system/kustomize/metal-operator-remote/scripts/
  ```

- [ ] **Step 6.5: Capture current Makefile metal-operator-remote section**

  Run:
  ```bash
  grep -n "metal-operator-remote\|KUSTOMIZE_METAL_OPERATOR_REMOTE" system/Makefile
  ```
  Note the line numbers — should include the variable definition (around line 170) and the targets `regen-metal-operator-remote`, `regen-metal-operator-remote-crds`, `regen-metal-operator-remote-webhooks` (around lines 172-188).

- [ ] **Step 6.6: Delete the Makefile regen targets and variable**

  Edit `system/Makefile`. Remove these lines (use the line numbers from Step 6.5):
  - The `KUSTOMIZE_METAL_OPERATOR_REMOTE := kustomize/metal-operator-remote` variable definition (around line 170)
  - The `regen-metal-operator-remote:` target and its body
  - The `regen-metal-operator-remote-crds:` target and its body
  - The `regen-metal-operator-remote-webhooks:` target and its body
  - Any `.PHONY:` line entries listing those targets

  Verify by running:
  ```bash
  grep -c "regen-metal-operator-remote\|KUSTOMIZE_METAL_OPERATOR_REMOTE" system/Makefile
  ```
  Expected output: `0`.

- [ ] **Step 6.7: Verify the Makefile still parses (other targets intact)**

  Run:
  ```bash
  cd system && make -n regen-ipam-capi-remote-crds 2>&1 | head -3
  ```
  Expected: a dry-run preview of the ipam target's recipe (or any other operator's regen target). If make returns "no rule to make target", verify the line edits didn't accidentally damage adjacent targets.

- [ ] **Step 6.8: Commit**

  ```bash
  git add -A system/kustomize/metal-operator-remote/host/base/ \
          system/kustomize/metal-operator-remote/scripts/ \
          system/Makefile
  git commit -m "chore(metal-operator-remote): delete obsolete pre-render machinery

Remove all the artifacts of the ManagedResource pipeline now that the
kustomize tree consumes upstream live via Git URL ref and applies directly
to host + workerless clusters:

  - host/base/webhook-config.yaml (ConfigMap, no longer read by sidecar)
  - scripts/wrap-managedresources.sh (MR-wrapping helper)
  - system/Makefile targets: regen-metal-operator-remote{,_crds,_webhooks}
  - KUSTOMIZE_METAL_OPERATOR_REMOTE variable definition

Other operators' regen-* Makefile targets (boot, ipam, argora, khalkeon)
are untouched; this change is metal-operator-remote-only per the scope
in proposal.md.

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 7: README and documentation

**Files:**
- Modify: `system/kustomize/metal-operator-remote/README.md`

- [ ] **Step 7.1: Update README's "Directory Layout" section**

  Edit `system/kustomize/metal-operator-remote/README.md`. The "Directory Layout" section should now describe the new structure. Replace the existing `remote/` subsection in the directory tree with:
  ```
  ├── remote/                         # APPLIED TO REMOTE (workerless cluster, Step 1)
  │   ├── kustomization.yaml          # composes upstream/crds-and-rbac + upstream/webhooks + custom
  │   ├── upstream/
  │   │   ├── crds-and-rbac/
  │   │   │   └── kustomization.yaml  # references upstream config/{crd,rbac} via Git URL ref
  │   │   └── webhooks/
  │   │       ├── kustomization.yaml          # OUTER LAYER: composes upstream-no-svc + namespace + ExternalName
  │   │       ├── upstream-no-svc/
  │   │       │   └── kustomization.yaml      # INNER LAYER: pulls upstream config/webhook + $patch:delete on Service
  │   │       ├── system-namespace.yaml       # creates Namespace "system" on workerless
  │   │       └── webhook-service-stub.yaml   # ExternalName Service: webhook-service/system → metal-operator-webhook-service
  │   └── custom/                     # Namespace metal-servers + custom RBAC + prod/qa Components
  ```
  Also update the `host/` subsection note to mention the consolidated `manager-patch.yaml` instead of the previous two split files.

- [ ] **Step 7.2: Add a "Cluster terminology" section near the top**

  Add a new section right after the introduction:
  ```markdown
  ## Cluster terminology

  This kustomize tree uses two cluster-role-neutral directory names. Their
  meaning in our deployment topology:

  | Directory | Meaning | Gardener equivalent |
  |---|---|---|
  | `host/` | **Workload cluster** — where the metal-operator controller pod actually runs (and where webhook callbacks land) | seed |
  | `remote/` | **Workerless cluster** — API server only, no nodes; receives CRDs, RBAC, the ValidatingWebhookConfiguration, and supporting Namespaces (`metal-servers` for user-facing CRs, `system` for the webhook-service ExternalName) | shoot |

  The workerless cluster's API server pod runs on the host cluster (Gardener-shoot
  topology; also kcp / vCluster). This co-location is what makes the
  ExternalName-based webhook routing work — see the "Webhook routing" section.
  ```

- [ ] **Step 7.3: Replace the "Upgrade upstream metal-operator version" section**

  The previous workflow used `make regen-metal-operator-remote`. Replace the section content with:
  ````markdown
  ### Upgrade upstream metal-operator version

  When a new version of `ironcore-dev/metal-operator` is released, edit the
  pinned tag in three `kustomization.yaml` files:

  ```bash
  # 1. Edit ?ref=v0.4.0 → ?ref=v<NEW> in:
  #    - host/base/kustomization.yaml
  #    - remote/upstream/crds-and-rbac/kustomization.yaml
  #    - remote/upstream/webhooks/upstream-no-svc/kustomization.yaml

  # 2. Verify the build still succeeds:
  kustomize build system/kustomize/metal-operator-remote/host/base/  > /dev/null && echo OK
  kustomize build system/kustomize/metal-operator-remote/remote/     > /dev/null && echo OK

  # 3. Diff against the previous tag for review:
  git diff -- system/kustomize/metal-operator-remote/

  # 4. Commit:
  git add system/kustomize/metal-operator-remote/
  git commit -m "chore(metal-operator-remote): bump upstream to v<NEW>"
  ```

  No regeneration script, no Makefile target — the kustomize Git URL refs
  pull upstream content live at every `kustomize build`.
  ````

- [ ] **Step 7.4: Add a "Webhook routing" section**

  Add a new section explaining the ExternalName-based routing (between the "Per-cluster overlays" and "Common Tasks" sections):
  ```markdown
  ## Webhook routing

  The workerless cluster's `ValidatingWebhookConfiguration` uses upstream's
  verbatim `clientConfig.service: { name: webhook-service, namespace: system }`
  form (no URL rewrite). When the workerless API server invokes a webhook,
  resolution goes:

  1. API server queries its own etcd: "Is there a Service `webhook-service`
     in namespace `system`?" Finds the **ExternalName** Service we deploy
     via `remote/upstream/webhooks/webhook-service-stub.yaml`.
  2. Reads `spec.externalName: metal-operator-webhook-service` (short name,
     identical for all clusters — no per-cluster customization).
  3. Resolves the short name via the API server pod's `/etc/resolv.conf`
     search paths to the host cluster's actual `metal-operator-webhook-service`
     ClusterIP (which kube-proxy routes to the controller pod's webhook
     server).

  This works because the workerless API server pod lives in the same
  Gardener-managed seed namespace as the metal-operator controller pod.
  Mirrors today's pre-rendered URL `https://metal-operator-webhook-service:443/...`
  pattern — same DNS-search-path mechanism, just expressed in `clientConfig.service`
  form instead of `clientConfig.url` form.

  No URL rewrite happens at any layer (build time, deploy time, or runtime).
  Upstream's webhook config is delivered verbatim except for the
  `$patch: delete` on upstream's regular Service (which would otherwise
  conflict with our ExternalName Service).
  ```

- [ ] **Step 7.5: Verify README parses as valid Markdown**

  Run:
  ```bash
  # If markdownlint is available:
  npx markdownlint system/kustomize/metal-operator-remote/README.md 2>/dev/null || echo "markdownlint not available; skipping"
  # Otherwise just visually inspect the rendered output via `gh markdown-preview` or by viewing on GitHub after push.
  ```

- [ ] **Step 7.6: Commit**

  ```bash
  git add system/kustomize/metal-operator-remote/README.md
  git commit -m "docs(metal-operator-remote): document dual-kustomize + ExternalName routing

Update the README to:
  - Describe the new directory layout (two-layer remote/upstream/webhooks/,
    consolidated host/base/manager-patch.yaml)
  - Add a "Cluster terminology" section mapping host/remote → workload/workerless
    (and Gardener seed/shoot)
  - Add a "Webhook routing" section documenting the ExternalName-based
    cross-cluster webhook resolution mechanism
  - Replace the \"Upgrade upstream metal-operator version\" workflow with the
    new \"edit ?ref= in three kustomization.yaml files\" recipe (no regen step)

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 8: End-to-end validation against expected behavior

**Files:** Read-only — no source edits in this task. Validation only.

- [ ] **Step 8.1: Run OpenSpec validation**

  Run:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  openspec validate replace-managedresource-with-dual-kustomize --strict
  ```
  Expected output: `Change 'replace-managedresource-with-dual-kustomize' is valid`.

- [ ] **Step 8.2: Build both roots independently**

  Run:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /tmp/host.yaml
  kustomize build system/kustomize/metal-operator-remote/remote/    > /tmp/remote.yaml
  echo "host.yaml: $(wc -l < /tmp/host.yaml) lines, $(yq -d'*' '.kind' /tmp/host.yaml | sort -u | wc -l) distinct kinds"
  echo "remote.yaml: $(wc -l < /tmp/remote.yaml) lines, $(yq -d'*' '.kind' /tmp/remote.yaml | sort -u | wc -l) distinct kinds"
  ```
  Expected: both succeed; host.yaml has ~10 distinct kinds, remote.yaml has ~9 distinct kinds.

- [ ] **Step 8.3: Sanity-check host resource categorization**

  Run:
  ```bash
  yq -d'*' '.kind' /tmp/host.yaml | sort | uniq -c
  ```
  Expected output:
  ```
        1 ConfigMap          # remote-kubeconfig (no webhook-config!)
        1 Deployment
        1 Ingress
        5 NetworkPolicy
        1 Role
        1 RoleBinding
        3 Secret
        2 Service
        1 ServiceAccount
  ```
  No `ManagedResource`, no `webhook-config` ConfigMap.

- [ ] **Step 8.4: Sanity-check remote resource categorization**

  Run:
  ```bash
  yq -d'*' '.kind' /tmp/remote.yaml | sort | uniq -c
  ```
  Expected (counts may vary slightly based on custom RBAC):
  ```
       55 ClusterRole
      ≥10 ClusterRoleBinding
       16 CustomResourceDefinition
        1 Role             # un-converted from upstream
        1 RoleBinding      # un-converted from upstream
        2 Namespace        # metal-servers + system
        1 Service          # webhook-service ExternalName
        2 ServiceAccount
        1 ValidatingWebhookConfiguration
  ```
  No `ManagedResource`. Roles/RoleBindings preserved (un-converted).

- [ ] **Step 8.5: Verify caBundle invariant**

  Run:
  ```bash
  yq -d'*' '.. | select(has("caBundle"))? // "missing"' /tmp/remote.yaml | grep -v "^missing$" | grep -v "^---$"
  ```
  Expected output: empty.

- [ ] **Step 8.6: Verify ExternalName Service shape on workerless**

  Run:
  ```bash
  yq -d'*' 'select(.kind == "Service" and .metadata.namespace == "system") | {name: .metadata.name, type: .spec.type, externalName: .spec.externalName}' /tmp/remote.yaml
  ```
  Expected:
  ```yaml
  name: webhook-service
  type: ExternalName
  externalName: metal-operator-webhook-service
  ```

- [ ] **Step 8.7: Verify SAP manager args present in host Deployment**

  Run:
  ```bash
  yq -d'*' 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "manager") | .args' /tmp/host.yaml
  ```
  Expected: 6 SAP args (`--mac-prefixes-file`, `--probe-image`, `--probe-os-image`, `--insecure`, `--registry-url`, `--manager-namespace`).

- [ ] **Step 8.8: Verify webhook-injector sidecar mode env var present**

  Run:
  ```bash
  yq -d'*' 'select(.kind == "Deployment") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | {env: .env, args: .args}' /tmp/host.yaml
  ```
  Expected: `WEBHOOK_INJECTOR_MODE=ca-rotation` env var; `--webhook-config-name=validating-webhook-configuration` arg.

- [ ] **Step 8.9: End-to-end build via kube-secrets per-cluster overlay (cross-repo)**

  Run from a kube-secrets checkout:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/kube-secrets
  # On the in-flight branch openspec/replace-managedresource-with-dual-kustomize
  # (with TEST-PHASE refs pointing at the helm-charts feature branch):
  kustomize build values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/host/   > /tmp/rt-host.yaml
  kustomize build values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/remote/ > /tmp/rt-remote.yaml
  ```
  Expected: both succeed once the kube-secrets coordinated change is also implemented (kube-secrets-side plan TBD). If kube-secrets coordinated change isn't ready yet, this step is deferred to the merge coordination phase.

- [ ] **Step 8.10: Helm equivalence cross-check (smoke test)**

  Optional but valuable. Render the helm chart for a known cluster and compare top-level resources:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  helm template metal-operator-remote system/metal-operator-remote --values <kube-secrets-helm-values-for-rt-eu-de-1> 2>/dev/null > /tmp/helm-rendered.yaml || echo "Helm rendering needs values file"
  yq -d'*' '.kind' /tmp/helm-rendered.yaml | sort | uniq -c
  ```
  Compare against `/tmp/host.yaml` + `/tmp/remote.yaml` (after unwrapping the helm-rendered ManagedResources). Expect functional equivalence: same kinds, similar names. Document any divergence in a `cross-validation-report.md` (optional artifact).

---

## Task 9: Pull request preparation (REUSE existing PR #11633)

**Files:** No source edits. The existing PR [`sapcc/helm-charts#11633`](https://github.com/sapcc/helm-charts/pull/11633) "poc(metal): kustomize-based resource splitting for metal-operator-remote" on branch `poc/kustomize-metal-operator-remote` already bundles two prior scopes (the POC archive + move-cluster-overlays-to-kube-secrets). This change adds **Scope 3** to the same PR — no new branch, no new PR.

- [ ] **Step 9.1: Verify branch state**

  Run:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  git branch --show-current
  git log --oneline master..HEAD | head -20
  ```
  Expected: branch is `poc/kustomize-metal-operator-remote`; the new commits from Tasks 2-7 sit on top of the prior Scope 1 + Scope 2 commits.

- [ ] **Step 9.2: Push branch to existing remote**

  Run:
  ```bash
  git push origin poc/kustomize-metal-operator-remote
  ```
  No `-u` flag needed (branch already tracks `origin/poc/kustomize-metal-operator-remote`).

- [ ] **Step 9.3: Update PR description to add Scope 3 section**

  The PR description currently has two `## Scope N` sections. Add a third section describing this change. Run:
  ```bash
  gh pr view 11633 --json body --jq .body > /tmp/pr-11633-body.md
  # Edit /tmp/pr-11633-body.md to add the Scope 3 section described below
  gh pr edit 11633 --body-file /tmp/pr-11633-body.md
  ```

  Insert the following section AFTER the existing "Scope 2 — Move per-cluster overlays to `cc/kube-secrets`" section and BEFORE the "How to verify locally" section:

  ````markdown
  ---

  ## Scope 3 — Replace ManagedResource pipeline with dual-kustomize apply

  Spec-tracked under `openspec/changes/replace-managedresource-with-dual-kustomize/` (brainstorm, design, proposal, specs, tasks, plan, verify).

  ### What changed (replace-MR scope)

  **Restructured: `system/kustomize/metal-operator-remote/remote/`**

  - `remote/upstream/crds-and-rbac/kustomization.yaml` — now references upstream `config/{crd,rbac}` directly via Git URL ref. Drops the `Role → ClusterRole` conversion patches (GRM-era workaround; un-converted Roles confirmed working in production by the helm chart's bundled `managedresources/crds-and-rbac.yaml`). Excludes the upstream metrics Service.
  - `remote/upstream/webhooks/` — restructured into a **two-layer kustomize** structure:
    - Inner `upstream-no-svc/kustomization.yaml`: pulls upstream `config/webhook` directory, applies `$patch: delete` to remove upstream's regular ClusterIP Service.
    - Outer `kustomization.yaml`: composes inner output + `system-namespace.yaml` (creates Namespace `system` on workerless) + `webhook-service-stub.yaml` (ExternalName Service `webhook-service` in `system` → `metal-operator-webhook-service` short name).
  - New `remote/kustomization.yaml`: composes `upstream/crds-and-rbac` + `upstream/webhooks` + `custom`. This is the workerless-cluster's deploy target (consumed by the kube-secrets per-cluster overlay's `remote/` subpath).

  **Restructured: `system/kustomize/metal-operator-remote/host/base/`**

  - Two patch files (`manager-remote-patch.yaml`, `manager-webhook-patch.yaml`) consolidated into a single `manager-patch.yaml` — all controller-manager Deployment customizations (env, args, volumes, ports, securityContext, network labels, hostNetwork, resources) in one reviewable place. The Pod-level `serviceAccountName` override lives in the webhook-injector Component now (see "Component encapsulation" below).
  - **Restored 6 SAP-specific manager args** missed by the kustomize POC (only `--leader-elect` from upstream was present). Now includes: `--mac-prefixes-file`, `--probe-image`, `--probe-os-image`, `--insecure`, `--registry-url`, `--manager-namespace`.
  - `webhook-config.yaml` ConfigMap **deleted** — no longer needed because the workerless `remote/` kustomize root is the source-of-truth for the `ValidatingWebhookConfiguration`.
  - `webhook-injector-rbac.yaml` Role narrowed (drops ConfigMap access; keeps events/secrets/leases) AND moved into the webhook-injector Component (see "Component encapsulation" below).

  **Component encapsulation: `system/kustomize/metal-operator-remote/components/webhook-injector/`**

  - The webhook-injector Component now owns ALL host-side resources whose existence originated with the sidecar feature in commit `9ffb1dc0c3`. The Component contents:
    - `sidecar.yaml` — initContainer patch (caBundle-rotation mode env + args, volume mounts, probes) AND `serviceAccountName` override on the controller-manager Deployment (single patch).
    - `webhook-injector-rbac.yaml` — moved here from `host/base/`. SA + Role (events/secrets/leases) + RoleBinding for the manager Pod's SA.
    - `kustomization.yaml` — Component header + `resources: [webhook-injector-rbac.yaml]` + `patches: [sidecar.yaml]` + image override.
  - Including the Component atomically introduces all sidecar prerequisites; excluding the Component atomically removes them. The Component is effectively mandatory for the metal-operator-remote topology.

  **Sidecar configuration: `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`**

  - Adds `WEBHOOK_INJECTOR_MODE=ca-rotation` env var (binary mode signal — coordinated with [`SAP-cloud-infrastructure/webhook-injector#9`](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9)).
  - Updates `--webhook-config-name` from `webhook-config` (local ConfigMap, no longer deployed) to `validating-webhook-configuration` (the workerless `ValidatingWebhookConfiguration` name from upstream).
  - In ca-rotation mode, the sidecar reads the existing workerless WebhookConfiguration and patches only its `caBundle` field — does NOT create or replace the resource.

  **Deletions:**
  - `system/Makefile` targets: `regen-metal-operator-remote`, `regen-metal-operator-remote-crds`, `regen-metal-operator-remote-webhooks` + `KUSTOMIZE_METAL_OPERATOR_REMOTE` variable.
  - `system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh`.
  - `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml`.
  - `system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml`.
  - `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml`.
  - `system/kustomize/metal-operator-remote/host/base/{manager-remote-patch,manager-webhook-patch,webhook-config}.yaml`.
  - `system/kustomize/metal-operator-remote/remote/upstream/{crds-and-rbac,webhooks}/source/` (subdirectories).

  **Documentation: `system/kustomize/metal-operator-remote/README.md`**

  - New "Cluster terminology" section mapping `host/` ≡ workload cluster, `remote/` ≡ workerless cluster.
  - New "Webhook routing" section explaining the ExternalName-based cross-cluster resolution.
  - "Upgrade upstream metal-operator version" workflow rewritten — no `make regen-*`, just edit `?ref=` in three `kustomization.yaml` files.

  ### Spec deltas (applied at archive)

  - `kustomize-resource-splitting`: 8 ADDED (including `Per-environment component composition delegated to kube-secrets per-cluster overlays` clarifying the prod/qa Component application contract), 5 MODIFIED, 1 REMOVED (`Remote resources pre-rendered as ManagedResource wrappers`).
  - `kustomize-sidecar-injection`: 5 ADDED (including `Webhook-injector Component encapsulates all sidecar-introduced resources` added during PR review), 1 MODIFIED.
  - `webhook-url-rendering`: 3 REMOVED (entire capability becomes empty — follow-up change to clean up).

  ### Validation (Scope 3)

  | Check | Result |
  |---|---|
  | `openspec validate replace-managedresource-with-dual-kustomize --strict` | ✓ |
  | `kustomize build system/kustomize/metal-operator-remote/host/base/` | ✓ |
  | `kustomize build system/kustomize/metal-operator-remote/remote/` | ✓ |
  | No `ManagedResource` in either build | ✓ |
  | No `caBundle` field in workerless build (apply-preservation invariant) | ✓ |
  | `webhook-service` ExternalName in workerless `system` namespace | ✓ |
  | All 6 SAP manager args restored in host Deployment | ✓ |
  | `WEBHOOK_INJECTOR_MODE=ca-rotation` env var on sidecar | ✓ |

  ### Pre-merge gates (Scope 3)

  - **Coordinated `cc/kube-secrets` PR (TBD)**: needs the dual-target Concourse pipeline + per-cluster overlay restructure. OpenSpec change scaffolded at `cc/kube-secrets:openspec/changes/replace-managedresource-with-dual-kustomize/` (brainstorm + proposal complete; remaining artifacts in flight).
  - **`SAP-cloud-infrastructure/webhook-injector#9`**: binary needs `WEBHOOK_INJECTOR_MODE=ca-rotation` mode published before production cutover. PR can merge to master regardless (pipelines stay in `triggers: "NOMATCH"` disabled state until cutover).

  ### Apply order (cross-repo, Scope 3)

  Same pattern as Scope 2: this PR merges first → kube-secrets author flips TEST-PHASE refs to `?ref=master` and merges → operator-driven per-cluster cutover (separate runbook activity, runbook lives in kube-secrets).

  ### Cross-repo coordination (Scope 3)

  - kube-secrets coordinated change: `/Users/D065300/IdeaProjects/sapcc/kube-secrets` branch `openspec/replace-managedresource-with-dual-kustomize` (brainstorm.md + proposal.md scaffolded; tracking issue TBD)
  - webhook-injector binary issue: https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9
  ````

- [ ] **Step 9.4: Verify reviewers and PR state**

  Run:
  ```bash
  gh pr view 11633 --json reviewRequests,isDraft,labels,milestone
  ```
  If reviewers from prior scopes are still appropriate, no change needed. Otherwise add controllers-team / sap-cc-platform-team handles via `gh pr edit 11633 --add-reviewer ...`.

- [ ] **Step 9.5: Mark PR as draft if pre-merge gates not yet satisfied**

  If webhook-injector#9 is not yet merged AND/OR the kube-secrets companion change is not yet ready, ensure PR #11633 stays in draft state. Run:
  ```bash
  gh pr ready 11633 --undo
  ```
  to mark as draft, or:
  ```bash
  gh pr ready 11633
  ```
  to mark as ready-for-review when all gates are aligned.

- [ ] **Step 9.6: Add a comment summarizing the Scope 3 push for reviewers tracking the PR**

  Run:
  ```bash
  gh pr comment 11633 --body "## Scope 3 added: replace-managedresource-with-dual-kustomize

Pushed Scope 3 (replace ManagedResource pipeline with dual-kustomize apply). PR description updated with full Scope 3 section.

Highlights:
- Drops ManagedResource wrapping from \`remote/\` (direct \`kubectl apply -k\` to workerless cluster)
- Two-layer webhook delivery via ExternalName Service in workerless \`system\` namespace (no URL rewrite, no pre-rendered file)
- Consolidates manager patches and restores 6 SAP-specific manager args missed by the kustomize POC
- Narrows webhook-injector sidecar to caBundle-rotation mode (coordinated via SAP-cloud-infrastructure/webhook-injector#9)
- Drops Role→ClusterRole conversion (GRM-era workaround)
- Deletes \`system/Makefile\` regen targets and \`scripts/wrap-managedresources.sh\`

Spec validation: ✓ \`openspec validate replace-managedresource-with-dual-kustomize --strict\` clean.

Tracking: cc/unified-kubernetes#831"
  ```

---

## Task 10: Pre-merge final checks

- [ ] **Step 10.1: Re-run OpenSpec validation**

  Run:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  openspec validate replace-managedresource-with-dual-kustomize --strict
  ```
  Expected: clean.

- [ ] **Step 10.2: Re-run both kustomize builds**

  Run:
  ```bash
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /dev/null && echo OK
  kustomize build system/kustomize/metal-operator-remote/remote/    > /dev/null && echo OK
  ```
  Both must print `OK`.

- [ ] **Step 10.3: Re-run kube-secrets per-cluster overlay builds against this branch**

  Run from kube-secrets checkout (with TEST-PHASE refs flipped):
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/kube-secrets
  for cluster in runtime/eu-de-1/rt-eu-de-1 admin-k3s/qa-de-1/a-qa-de-200; do
    for target in host remote; do
      kustomize build values/kustomize/$cluster/metal-operator-remote/$target/ > /dev/null && echo "$cluster/$target OK"
    done
  done
  ```
  Expected: all four `OK` lines.

- [ ] **Step 10.4: Confirm coordinated kube-secrets PR is ready**

  Communicate with kube-secrets companion PR author (yourself, since you authored #3905). Confirm both PRs are reviewable and timed for the same merge window.

- [ ] **Step 10.5: Confirm webhook-injector image availability**

  Check `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest` (or a specific tag) supports `WEBHOOK_INJECTOR_MODE=ca-rotation`. Run:
  ```bash
  # Locally, ad-hoc test:
  docker run --rm keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector:latest --help 2>&1 | grep -i 'mode\|ca-rotation' || echo "Mode not yet supported in published image"
  ```
  If "Mode not yet supported", PR can still merge to `master` (pipelines stay in `triggers: "NOMATCH"`); production cutover is gated.

---

## Task 11: Merge

- [ ] **Step 11.1: Coordinate merge timing with kube-secrets PR**

  Both PRs should land in the same change window. Helm-charts merges first (so kube-secrets's TEST-PHASE refs can flip to `?ref=master`).

- [ ] **Step 11.2: Merge helm-charts PR after coordinated review**

  Via GitHub UI or:
  ```bash
  gh pr merge --squash --delete-branch
  ```

- [ ] **Step 11.3: Verify on master**

  Run:
  ```bash
  git checkout master && git pull --ff-only
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /dev/null && echo OK
  kustomize build system/kustomize/metal-operator-remote/remote/    > /dev/null && echo OK
  test ! -f system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh && echo OK
  test ! -f system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml && echo OK
  test ! -f system/kustomize/metal-operator-remote/host/base/webhook-config.yaml && echo OK
  ```
  All five `OK` lines must print.

---

## Task 12: Archive the OpenSpec change

- [ ] **Step 12.1: Run openspec archive**

  Run:
  ```bash
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  openspec archive replace-managedresource-with-dual-kustomize
  ```
  This applies the spec deltas to `openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection,webhook-url-rendering}/spec.md` and moves the change directory to `openspec/changes/archive/<date>-replace-managedresource-with-dual-kustomize/`.

- [ ] **Step 12.2: Verify spec deltas applied correctly**

  Run:
  ```bash
  grep -c 'ManagedResource' openspec/specs/kustomize-resource-splitting/spec.md
  ```
  Expected: `0` (the requirement was removed).

  Run:
  ```bash
  grep -c 'caBundle\|ca-rotation' openspec/specs/kustomize-sidecar-injection/spec.md
  ```
  Expected: `≥3` matches (the new requirements added).

- [ ] **Step 12.3: Run final validation**

  Run:
  ```bash
  openspec validate --all --strict
  ```
  Expected output: all specs pass.

- [ ] **Step 12.4: Commit and push the archived change**

  Run:
  ```bash
  git add openspec/
  git commit -m "chore(openspec): archive replace-managedresource-with-dual-kustomize

Sync spec deltas to openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection,webhook-url-rendering}/spec.md.

Tracking: cc/unified-kubernetes#831"
  git push origin master
  ```

---

## Task 13: Hand-off and production cutover (post-merge)

- [ ] **Step 13.1: Notify operators of merge**

  Send a notification to the operators / sap-cc-platform team channel summarizing:
  - helm-charts PR merged (link)
  - kube-secrets PR merged (link, after that lands too)
  - Pipelines remain in `triggers: "NOMATCH"` disabled state
  - Per-cluster cutover is operator-driven via the runbook

- [ ] **Step 13.2: Document the per-cluster cutover runbook in cc/kube-secrets**

  This is owned by the kube-secrets coordinated change's verify.md or a separate runbook document. Should cover:
  1. Operator picks a cluster (e.g., `rt-eu-de-1`)
  2. Manually trigger `<cluster>-remote-diff` in Concourse → review diff
  3. Manually trigger `<cluster>-remote-apply` → workerless gets CRDs + RBAC + Namespace + ExternalName Service + WebhookConfig (caBundle empty)
  4. Manually trigger `<cluster>-host-diff` → review
  5. Manually trigger `<cluster>-host-apply` → host gets controller pod + sidecar; sidecar populates caBundle on workerless WebhookConfig
  6. Soak: verify `kubectl get vwc -o yaml` on workerless shows caBundle populated; test a metal-operator CR write
  7. Decommission the legacy helm pipeline for the cluster (per the prior change's "DECOMMISSION CANDIDATE" comments)

- [ ] **Step 13.3: Track follow-up — delete legacy helm chart**

  Once all production clusters cut over, file a follow-up issue/change to delete `system/metal-operator-remote/` (the legacy helm chart). This is a separate OpenSpec change (lightweight: just file deletes + Chart.lock cleanup).

- [ ] **Step 13.4: Track follow-up — `webhook-url-rendering` capability cleanup**

  After this change archives, the `webhook-url-rendering` capability spec at `openspec/specs/webhook-url-rendering/spec.md` has all 3 requirements REMOVED (only Purpose section remains). File a follow-up OpenSpec change to either delete the capability directory or repurpose it for new requirements.

- [ ] **Step 13.5: Track follow-up — multi-operator generalization**

  Per epic #831, the same dual-kustomize pattern should extend to `boot, ipam, argora, khalkeon`. Whoever picks up operator #2 should consider extracting reusable scaffolding (a kustomize Component or templated tree).

- [ ] **Step 13.6: Track follow-up — structured-auth migration**

  The Gardener-managed token rotation (per `serviceaccount.resources.gardener.cloud/*` annotations on `remote-serviceaccount-secret.yaml` and `rotate-kubeconfig-secret.yaml`) is a separate workstream tracked in epic #831's "Solved" section. This change is neutral to that migration.

- [ ] **Step 13.7: Track follow-up — verify-phase open questions**

  From the brainstorm Open Questions: Deployment name mismatch (helm `metal-operator-controller-manager` vs kustomize `controller-manager`), behavior under network partitions, cluster teardown procedure documentation. Decide which become verify-phase tests and which become runbook additions.

---

## Self-Review

After writing the plan, sanity check against the spec.

**Spec coverage check:**

- ✓ "Two cluster-targeted kustomize roots produce direct-apply YAML" → Tasks 2, 3, 4, validated in Task 8
- ✓ "Apply pipeline targets kube-secrets per-cluster overlays" → documented in Task 9 PR description; validated via Task 8.9
- ✓ "System converges to working admission validation regardless of apply order" → no implementation needed (emergent property of the components); documented in proposal.md and design.md
- ✓ "Build via kustomize Git URL ref consumes upstream live" → Tasks 2.3, 3.2; verified in Task 8
- ✓ "Upstream RBAC applied verbatim" → Task 3.2 (drop Role→ClusterRole patch); Task 3.4 verifies
- ✓ "Workerless cluster receives system namespace and webhook-service ExternalName" → Tasks 2.5, 2.6
- ✓ "Webhook delivery via ExternalName routing" → Task 2 entirely
- ✓ "Webhook-injector sidecar configured for caBundle-rotation mode" → Task 5
- ✓ "Webhook-injector ServiceAccount granted narrowed RBAC for caBundle rotation" → Task 5.4 (host side); remote-side ClusterRole noted as kube-secrets concern
- ✓ "Local webhook-config ConfigMap on host is not deployed" → Task 6.1, 6.3
- ✓ "Kustomize tree must not emit caBundle in webhook configs" → Task 2.10, Task 8.5
- ✓ Manager args restoration → Task 4 entirely
- ✓ Pre-render machinery deletion → Task 6
- ✓ webhook-url-rendering REMOVED requirements → applied automatically at Task 12 archive

**Placeholder scan:** No "TBD" / "TODO" / "implement later" in concrete code/edit steps. Cross-repo references (kube-secrets PR number, webhook-injector image tag) are flagged as "TBD" only where the dependency is genuinely external; the steps describe what to verify, not what to invent.

**Type consistency:** Resource names checked: `controller-manager` (kustomize Deployment name), `metal-operator-webhook-service` (host Service name), `webhook-service` (workerless ExternalName Service name), `validating-webhook-configuration` (workerless WebhookConfig name from upstream), `metal-operator-webhook-injector` (sidecar SA/Role/RoleBinding name) — all consistent across tasks.

---

## Execution Handoff

**Plan complete and saved to `openspec/changes/replace-managedresource-with-dual-kustomize/plan.md`.**

Per the OpenSpec workflow (sdd-plus-superpowers schema), the apply phase will be invoked via `/opsx-apply` and uses **subagent-driven-development** to dispatch a fresh subagent per task with two-stage review. This is the recommended path.

To execute:
```
/opsx-apply replace-managedresource-with-dual-kustomize
```
