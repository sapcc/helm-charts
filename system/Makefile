CLUSTER_API_VERSION ?= v1.13.4
PROVIDER_METAL3_VERSION ?= v1.13.1
PROVIDER_METAL_VERSION ?= cf12acd520aa203db28f21a326a61fddc9720b95
PROVIDER_IPAM_VERSION ?= v1.1.1-rc.0
PROVIDER_HELM ?= v0.6.4
PROVIDER_KUBERNIKUS_VERSION ?= 9ef3fb8f8b42f5606edb5044693adf62d434d4e0
BAREMETAL_OPERATOR_VERSION ?= v0.13.1

SHELL := bash
.ONESHELL:

UNAME_S := $(shell uname -s)
SED := sed
ifeq ($(UNAME_S),Darwin)
	SED := gsed
endif

build: build-cluster-api-core build-controlplane-kubeadm build-bootstrap-kubeadm build-provider-metal3 build-provider-kubernikus build-provider-helm build-provider-ipam build-ipam-capi-remote build-provider-metal3 build-provider-metal

build-cluster-api-core:
	$(call build-chart,cluster-api-core,https://github.com/kubernetes-sigs/cluster-api//config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,cluster-api-core)
	@find cluster-api-core/crds -type f -exec $(SED) -i -e 's#capi-system#capi#g' {} \;
	@find cluster-api-core/templates -type f -exec $(SED) -i -e 's#/{{ include "cluster-api-core.fullname" . }}-system/#/#g' {} \;
	@find cluster-api-core/templates -type f -exec $(SED) -i -e 's#-system.#.#g' {} \;
	@# Label CRDs so clusterctl move discovers them (the core Cluster/Machine/
	@# KubeadmControlPlane graph is the root of the ownerRef chain clusterctl walks;
	@# without this label a non-clusterctl-init install is invisible to `clusterctl move`)
	@find cluster-api-core/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' cluster-api-core/values.yaml
	@yq -i '.fullnameOverride="capi"' cluster-api-core/values.yaml

build-controlplane-kubeadm:
	$(call build-chart,controlplane-kubeadm,https://github.com/kubernetes-sigs/cluster-api//controlplane/kubeadm/config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,controlplane-kubeadm)
	@find controlplane-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-control-plane-system#capi#g' {} \;
	@find controlplane-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-control-plane-serving-cert#capi-kubeadm-controlplane-serving-cert#g' {} \;
	@find controlplane-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-control-plane-webhook-service#capi-kubeadm-controlplane-webhook-service#g' {} \;
	@find controlplane-kubeadm/templates -type f -exec $(SED) -i -e 's#capi-kubeadm-control-plane-serving-cert#capi-kubeadm-controlplane-serving-cert#g' {} \;
	@find controlplane-kubeadm/templates -type f -exec $(SED) -i -e 's#capi-kubeadm-control-plane-webhook-service#capi-kubeadm-controlplane-webhook-service#g' {} \;
	@find controlplane-kubeadm/templates -type f -exec $(SED) -i -e 's#/{{ include "controlplane-kubeadm.fullname" . }}-system/#/#g' {} \;
	@find controlplane-kubeadm/templates -type f -exec $(SED) -i -e 's#-kubeadm-control-plane-system.#.#g' {} \;
	@$(SED) -i 's/10240/30720/g' controlplane-kubeadm/crds/*
	@# Label CRDs so clusterctl move discovers them (KubeadmControlPlane is in the
	@# Cluster ownerRef chain clusterctl walks)
	@find controlplane-kubeadm/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' controlplane-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-controlplane"' controlplane-kubeadm/values.yaml

# fix for "spec.ignition.containerLinuxConfig.additionalConfig: Too long: may not be longer than 10240"
build-bootstrap-kubeadm:
	$(call build-chart,bootstrap-kubeadm,https://github.com/kubernetes-sigs/cluster-api//bootstrap/kubeadm/config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,bootstrap-kubeadm)
	@find bootstrap-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-bootstrap-system#capi#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#/{{ include "bootstrap-kubeadm.fullname" . }}-system/#/#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#-kubeadm-bootstrap-system.#.#g' {} \;
	@$(SED) -i 's/10240/30720/g' bootstrap-kubeadm/crds/*
	@# Label CRDs so clusterctl move discovers them (KubeadmConfig is owned by the
	@# Machines in the Cluster ownerRef chain clusterctl walks)
	@find bootstrap-kubeadm/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' bootstrap-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-bootstrap"' bootstrap-kubeadm/values.yaml

build-provider-helm:
	$(call build-chart,provider-helm,https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm//config/default,$(PROVIDER_HELM))
	$(call fix-crds,provider-helm)
	@# Label CRDs so clusterctl move discovers them (HelmChartProxy/HelmReleaseProxy
	@# are in the Cluster ownerRef chain clusterctl walks)
	@find provider-helm/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@find provider-helm/templates -type f -exec $(SED) -i -e 's#webhook-server-cert#caaph-webhook-server-cert#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_HELM)"' provider-helm/values.yaml
	@yq -i '.fullnameOverride="caaph"' provider-helm/values.yaml

build-provider-ipam:
	$(call build-chart,provider-ipam,https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/default,$(PROVIDER_IPAM_VERSION))
	$(call fix-crds,provider-ipam)
	@# Label CRDs so clusterctl move discovers them
	@find provider-ipam/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@find provider-ipam/crds -type f -exec $(SED) -i -e 's#capi-capi-#capi-#g' {} \;
	@find provider-ipam/templates -type f -exec $(SED) -i -e 's#capi-capi-#capi-#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_IPAM_VERSION)"' provider-ipam/values.yaml
	@yq -i '.fullnameOverride="capi-capi-provider-ipam"' provider-ipam/values.yaml

build-ipam-capi-remote:
	@CHART_VERSION=$$(yq '.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join(".")' ipam-capi-remote/Chart.yaml 2>/dev/null || echo "0.1.0")
	@rm -rf ipam-capi-remote
	@cat kustomize/ipam-capi-remote/manager/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir ipam-capi-remote
	@$(SED) -i -e '/^      containers:/i\      initContainers:\n      {{- include "chart.webhook-injector-sidecar" . | nindent 6 }}' ipam-capi-remote/templates/deployment.yaml
	@cp kustomize/ipam-capi-remote/templates/* ipam-capi-remote/templates
	@mkdir ipam-capi-remote/managedresources
	@kubectl kustomize kustomize/ipam-capi-remote/managedresources > ipam-capi-remote/managedresources/crds-rbac.yaml
	@cp kustomize/ipam-capi-remote/managedresources/rbac.yaml ipam-capi-remote/managedresources
	@cp kustomize/ipam-capi-remote/managedresources/globalinclusterippool.yaml ipam-capi-remote/managedresources
	@kubectl kustomize kustomize/ipam-capi-remote/webhooks | \
		yq eval 'select(.kind != "Service") | .metadata.name = "ipam-capi-remote-" + .metadata.name | (.webhooks[].clientConfig | select(.service)) |= ({"url": "https://ipam-capi-remote-webhook-service:443" + .service.path})' - > ipam-capi-remote/webhooks.yaml
	@yq eval-all '. as $$item ireduce ({}; . * $$item)' ipam-capi-remote/values.yaml kustomize/ipam-capi-remote/values-override.yaml | \
		yq eval -i '. *= load("/dev/stdin")' ipam-capi-remote/values.yaml
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_IPAM_VERSION)"' ipam-capi-remote/values.yaml
	@yq -i ".version=\"$$CHART_VERSION\"" ipam-capi-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: {{ .Values.controllerManager.serviceAccountName }}/g' ipam-capi-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' ipam-capi-remote/managedresources/crds-rbac.yaml
	@git restore kustomization.yaml

build-provider-metal3:
	$(call build-chart,provider-metal3,https://github.com/metal3-io/cluster-api-provider-metal3//config/default,$(PROVIDER_METAL3_VERSION))
	$(call fix-crds,provider-metal3)
	@# hacky fix for ipam
	@find provider-metal3/crds -type f -exec $(SED) -i -e 's#capm3-system/#capi/#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#.capm3-system.#.capi.#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#/{{ include "provider-metal3.fullname" . }}-system/#/#g' {} \;
	@# fix for "no matches for kind "IPClaim"
	@curl -sSL https://raw.githubusercontent.com/metal3-io/ip-address-manager/$(PROVIDER_METAL3_VERSION)/config/crd/bases/ipam.metal3.io_ipclaims.yaml -o provider-metal3/crds/ipam.metal3.io_ipclaims.yaml
	@# Label CRDs so clusterctl move discovers them (Metal3Cluster/Metal3Machine are
	@# in the Cluster ownerRef chain clusterctl walks)
	@find provider-metal3/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL3_VERSION)"' provider-metal3/values.yaml
	@yq -i '.fullnameOverride="capm3"' provider-metal3/values.yaml

build-provider-metal:
	$(call build-chart,provider-metal,https://github.com/ironcore-dev/cluster-api-provider-ironcore-metal//config/default,$(PROVIDER_METAL_VERSION))
	$(call fix-crds,provider-metal)
	@# Label CRDs so clusterctl move discovers them (IroncoreMetalMachine is a link
	@# in the ownerRef chain IPAddressClaim -> ServerClaim -> IroncoreMetalMachine -> Machine -> Cluster)
	@find provider-metal/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL_VERSION)"' provider-metal/values.yaml
	@yq -i '.fullnameOverride="provider-metal"' provider-metal/values.yaml

build-provider-kubernikus:
	$(call build-chart,provider-kubernikus,https://github.com/sapcc/cluster-api-control-plane-provider-kubernikus//config/default,$(PROVIDER_KUBERNIKUS_VERSION))
	@# helmify names the manager ClusterRole after the upstream role ("cluster-api-control-plane-provider-kubernikus"),
	@# producing capi-cp-provider-kubernikus-cluster-api-control-plane-provider-kubernikus. That's the manager role,
	@# so rename it back to <fullname>-manager-role and keep the manager rolebinding pointing at it. Renaming an
	@# existing ClusterRoleBinding.roleRef is rejected by the API server, so this stability matters across bumps.
	@if [ -f provider-kubernikus/templates/cluster-api-control-plane-provider-kubernikus-rbac.yaml ]; then \
		mv provider-kubernikus/templates/cluster-api-control-plane-provider-kubernikus-rbac.yaml \
		   provider-kubernikus/templates/manager-clusterrole.yaml; \
	fi
	@find provider-kubernikus/templates -type f -exec $(SED) -i -e 's#-cluster-api-control-plane-provider-kubernikus#-manager-role#g' {} \;
	@# Label CRDs so clusterctl move discovers them (KubernikusControlPlane is in the
	@# Cluster ownerRef chain clusterctl walks)
	@find provider-kubernikus/crds -type f | xargs -n1 yq -i '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""'
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_KUBERNIKUS_VERSION)"' provider-kubernikus/values.yaml
	@yq -i '.fullnameOverride="capi-cp-provider-kubernikus"' provider-kubernikus/values.yaml

build-baremetal-operator:
	@yq -i '.namespace = "baremetal-operator=system"' kustomization.yaml
	@yq -i '.namePrefix = "metal3-"' kustomization.yaml
	@yq -i '.images[0].name = "quay.io/metal3-io/baremetal-operator"' kustomization.yaml
	@yq -i '.images[0].newName = "quay.io/metal3-io/baremetal-operator"' kustomization.yaml
	@yq -i '.images[0].newTag = "$(BAREMETAL_OPERATOR_VERSION)"' kustomization.yaml
	@cat kustomization-m3-patches.yaml >> kustomization.yaml
	$(call build-chart,baremetal-operator-core,https://github.com/metal3-io/baremetal-operator//config/default,$(BAREMETAL_OPERATOR_VERSION))
	$(call fix-crds,baremetal-operator-core)
	@rm baremetal-operator-core/templates/ironic.yaml
	@find baremetal-operator-core/crds -type f -exec $(SED) -i -e 's#baremetal-operator-system/baremetal-operator-serving-cert#baremetal-operator-system/metal3-baremetal-operator-serving-cert#g' {} \;
	@find baremetal-operator-core/templates -type f -exec $(SED) -i -e 's#-baremetal-operator-system/#-#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(BAREMETAL_OPERATOR_VERSION)"' baremetal-operator-core/values.yaml
	@yq -i '.fullnameOverride="metal3"' baremetal-operator-core/values.yaml

build-metal-operator:
	@helm dep up metal-operator
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' metal-operator/Chart.yaml

build-metal-operator-remote:
	@helm dep up metal-operator-remote
	# Merge upstream manager defaults with our overrides into values.yaml
	@yq eval-all \
		'select(fileIndex == 0).manager * select(fileIndex == 1).manager | {"manager": .}' \
		<(tar -xzf metal-operator-remote/charts/metal-operator*.tgz -O metal-operator/values.yaml) \
		metal-operator-remote/values-overrides.yaml | \
		yq eval -i '. *= load("/dev/stdin")' metal-operator-remote/values.yaml
	@yq eval -i ".metaldata.image.tag = \"$$(tar -xzf metal-operator-remote/charts/metal-operator*.tgz -O metal-operator/values.yaml | yq eval '.metaldata.image.tag' -)\"" metal-operator-remote/values.yaml
	# Render CRDs, essential RBAC and metaldata for the shoot; manager Deployment is excluded (runs directly in this release).
	@helm template metal-operator metal-operator-remote/charts/metal-operator* \
		-n kube-system \
		-f metal-operator-remote/values-managed-resources.yaml | \
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration" and .kind != "MutatingWebhookConfiguration")' - | \
		yq eval '(select(.kind == "CustomResourceDefinition") | .metadata.labels."metal-operator-remote-webhook-injector") = "true"' - | \
		yq eval '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""' - \
		> metal-operator-remote/managedresources/crds-and-rbac.yaml
	# Patch upstream's Deployment: add webhook-injector sidecar, restore dns-record-template/ignition volumes (macdb unused, omitted), fix its extraVolume* nindent bug, and localize named-template includes.
	@tar -xzf metal-operator-remote/charts/metal-operator*.tgz -O metal-operator/templates/manager/manager.yaml | \
		$(SED) \
			-e '/namespace: {{ .Release.Namespace }}/d' \
			-e 's/include "metal-operator\./include "chart./g' \
			-e '/^          {{- if \.Values\.manager\.extraVolumeMounts }}$$/,/^          {{- end }}$$/c\          {{- range .Values.manager.extraVolumeMounts }}\n          {{- if not (and $$.Values.certManager.enable (eq .name "webhook-certs")) }}\n          {{- toYaml (list .) | nindent 8 }}\n          {{- end }}\n          {{- end }}' \
			-e '/^        {{- if \.Values\.manager\.extraVolumes }}$$/,/^        {{- end }}$$/c\      {{- range .Values.manager.extraVolumes }}\n      {{- if not (and $$.Values.certManager.enable (eq .name "webhook-certs")) }}\n      {{- toYaml (list .) | nindent 6 }}\n      {{- end }}\n      {{- end }}' \
			-e '/^        volumeMounts:$$/a\        {{- if .Values.manager.dnsRecordTemplate.enabled }}\n        - mountPath: /etc/metal-operator/dns\n          name: dns-record-template\n        {{- end }}\n        {{- if .Values.ignition.override }}\n        - name: ignition-template\n          mountPath: /etc/metal-operator\n          readOnly: true\n        {{- end }}' \
			-e '/^      volumes:$$/a\      {{- if .Values.manager.dnsRecordTemplate.enabled }}\n      - name: dns-record-template\n        configMap:\n          name: dns-record-template\n      {{- end }}\n      {{- if .Values.ignition.override }}\n      - name: ignition-template\n        configMap:\n          name: {{ include "chart.name" . }}-ignition-template\n      {{- end }}' \
			-e '/^      containers:/i\      initContainers:\n      {{- include "chart.webhook-injector-sidecar" . | nindent 6 }}'\
		> metal-operator-remote/templates/controller-manager.yaml
	@grep -q 'mountPath: /etc/metal-operator/dns' metal-operator-remote/templates/controller-manager.yaml && \
		grep -q -- '- name: dns-record-template' metal-operator-remote/templates/controller-manager.yaml && \
		[ "$$(grep -c -- '- name: ignition-template' metal-operator-remote/templates/controller-manager.yaml)" -ge 2 ] && \
		grep -q 'initContainers:' metal-operator-remote/templates/controller-manager.yaml && \
		grep -q 'include "chart.webhook-injector-sidecar"' metal-operator-remote/templates/controller-manager.yaml && \
		grep -q 'path: /healthz' metal-operator-remote/templates/controller-manager.yaml && \
		grep -q 'path: /readyz' metal-operator-remote/templates/controller-manager.yaml || \
		{ echo "ERROR: sed insertion anchors not found in controller-manager.yaml (dns-record-template/ignition-template volumes, webhook-injector-sidecar initContainers, or liveness/readiness probe paths) - upstream manager.yaml layout likely changed, update the sed anchors."; exit 1; }
	@echo "NOTE: controller-manager.yaml sed pipeline is best-effort - verify with 'helm lint'/'helm template' after regenerating."
	# Vendor the metaldata DaemonSet locally; it must run directly here too since the seed itself may be bare-metal.
	@tar -xzf metal-operator-remote/charts/metal-operator*.tgz -O metal-operator/templates/extras/metaldata.yaml | \
		$(SED) \
			-e '/namespace: {{ .Release.Namespace }}/d' \
			-e 's/include "metal-operator\./include "chart./g' \
			-e 's/\.Values\.metaldata\.image\.tag | default \.Chart\.AppVersion/required "metaldata.image.tag is required" .Values.metaldata.image.tag/' \
			-e '1i\# Vendored copy of metal-operator-core'"'"'s templates/extras/metaldata.yaml; must run directly here since the seed itself may be bare-metal.' \
		> metal-operator-remote/templates/metaldata.yaml
	@grep -q 'required "metaldata.image.tag is required" .Values.metaldata.image.tag' metal-operator-remote/templates/metaldata.yaml || \
		{ echo "ERROR: metaldata.image.tag required-guard substitution not found in metaldata.yaml - upstream extras/metaldata.yaml layout likely changed, update the sed anchor."; exit 1; }
	# templates/metaldata-rbac.yaml is hand-maintained (mirrors upstream's rbac/metaldata*.yaml, simplified) - update by hand if upstream changes.
	# Render webhook configurations and rewrite service refs to URL-based
	@helm template metal-operator metal-operator-remote/charts/metal-operator* \
	  -n kube-system \
		-f metal-operator-remote/values-managed-resources.yaml | \
		yq eval 'select(.kind == "ValidatingWebhookConfiguration" or .kind == "MutatingWebhookConfiguration") | (.webhooks[].clientConfig | select(.service)) |= ({"url": "https://metal-operator-remote-webhook-service:443" + .service.path})' - \
		> metal-operator-remote/webhooks.yaml
	# Bump patch version
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' metal-operator-remote/Chart.yaml


build-boot-operator:
	@helm dep up boot-operator
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' boot-operator/Chart.yaml

build-boot-operator-remote:
	@helm dep up boot-operator-remote
	@helm template boot-operator boot-operator-remote/charts/boot-operator* \
		-n kube-system \
		-f boot-operator-remote/values-managed-resources.yaml | \
		$(SED) 's/kind: Role/kind: ClusterRole/g' - | \
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration")' - | \
		yq eval '(select(.kind == "CustomResourceDefinition") | .metadata.labels."clusterctl.cluster.x-k8s.io") = ""' - >\
		boot-operator-remote/managedresources/crds-and-rbac.yaml
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' boot-operator-remote/Chart.yaml

build-metal-maintenance-operator-remote:
	@helm dep up metal-maintenance-operator-remote
	@helm template metal-maintenance-operator \
		metal-maintenance-operator-remote/charts/metal-maintenance-operator*.tgz \
		-n kube-system \
		-f metal-maintenance-operator-remote/values-managed-resources.yaml | \
		$(SED) 's/kind: Role/kind: ClusterRole/g' - | \
		yq eval 'select(.kind != "Service" and .kind != "Deployment" and .metadata.name != "metal-maintenance-operator-leader-election-role" and .metadata.name != "metal-maintenance-operator-leader-election-rolebinding")' - \
		> metal-maintenance-operator-remote/managedresources/crds-and-rbac.yaml
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' metal-maintenance-operator-remote/Chart.yaml

build-argora-operator:
	@helm dep up argora-operator
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' argora-operator/Chart.yaml

build-argora-operator-remote:
	@helm dep up argora-operator-remote
	@helm template argora-operator argora-operator-remote/charts/argora-* \
		-n kube-system \
		-f argora-operator-remote/values-managed-resources.yaml | \
		$(SED) 's/kind: Role/kind: ClusterRole/g' - | \
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration" and .kind != "ConfigMap" and .kind != "Secret")' - >\
		argora-operator-remote/managedresources/crds-and-rbac.yaml
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' argora-operator-remote/Chart.yaml

build-khalkeon-remote:
	@helm dep up khalkeon-remote
	@helm template khalkeon khalkeon-remote/charts/khalkeon* \
		-f khalkeon-remote/values.yaml \
		-f khalkeon-remote/values-managed-resources.yaml | \
		$(SED) 's/kind: Role/kind: ClusterRole/g' - | \
		yq eval 'select(.kind != "Service")' - >\
		khalkeon-remote/managedresources/crds-and-rbac.yaml
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' khalkeon-remote/Chart.yaml

# chart name, source url, tag
define build-chart
@echo "Generating Helm chart for $(1) version $(3)"
@if [ -f "$(1)/Chart.yaml" ]; then \
	CHART_VERSION=$$(yq '.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join(".")' $(1)/Chart.yaml); \
else \
	CHART_VERSION="0.1.0"; \
fi; \
yq -i '.resources[0] = "$(2)?ref=$(3)"' kustomization.yaml; \
rm -rf $(1); \
kubectl kustomize | helmify -crd-dir $(1); \
$(SED) -i -E 's/\$$\{[^:=]+\:=([^}]+)\}/\1/g' $(1)/values.yaml; \
yq -i '.appVersion="$(3)"' $(1)/Chart.yaml; \
yq -i ".version=\"$$CHART_VERSION\"" $(1)/Chart.yaml; \
git restore kustomization.yaml
endef

# chart name
define fix-crds
@echo "Fixing webhook certs for $(1)"
@# delete pre-filled caBundle
@find $(1)/crds -type f | xargs -n1 yq -i 'del(.spec.conversion.webhook.clientConfig.caBundle)'
@find $(1)/crds -type f | xargs -n1 yq -i 'del(.metadata.creationTimestamp)'
endef
