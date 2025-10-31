CLUSTER_API_VERSION ?= v1.11.2
PROVIDER_METAL3_VERSION ?= v1.11.1
PROVIDER_METAL_VERSION ?= 3c311063d94fe0ce7f229877a9370fb101b32bb2
PROVIDER_VSPHERE_VERSION ?= v1.9.3
PROVIDER_IPAM_VERSION ?= v1.0.3
PROVIDER_HELM ?= v0.4.1
PROVIDER_KUBERNIKUS_VERSION ?= b6d18b8c8e26336aec34ecadb76d8ec78cdaf67d
BAREMETAL_OPERATOR_VERSION ?= v0.11.1

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
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' cluster-api-core/values.yaml
	@yq -i '.fullnameOverride="capi"' cluster-api-core/values.yaml
	@yq -i '.version="1.0.0"' cluster-api-core/Chart.yaml

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
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' controlplane-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-controlplane"' controlplane-kubeadm/values.yaml
	@yq -i '.version="1.0.0"' controlplane-kubeadm/Chart.yaml

# fix for "spec.ignition.containerLinuxConfig.additionalConfig: Too long: may not be longer than 10240"
build-bootstrap-kubeadm:
	$(call build-chart,bootstrap-kubeadm,https://github.com/kubernetes-sigs/cluster-api//bootstrap/kubeadm/config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,bootstrap-kubeadm)
	@find bootstrap-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-bootstrap-system#capi#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#/{{ include "bootstrap-kubeadm.fullname" . }}-system/#/#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#-kubeadm-bootstrap-system.#.#g' {} \;
	@$(SED) -i 's/10240/30720/g' bootstrap-kubeadm/crds/*
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' bootstrap-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-bootstrap"' bootstrap-kubeadm/values.yaml
	@yq -i '.version="1.0.0"' bootstrap-kubeadm/Chart.yaml

build-provider-helm:
	$(call build-chart,provider-helm,https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm//config/default,$(PROVIDER_HELM))
	$(call fix-crds,provider-helm)
	@find provider-helm/templates -type f -exec $(SED) -i -e 's#webhook-server-cert#caaph-webhook-server-cert#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_HELM)"' provider-helm/values.yaml
	@yq -i '.fullnameOverride="caaph"' provider-helm/values.yaml
	@yq -i '.version="0.1.0"' provider-helm/Chart.yaml

build-provider-vsphere:
	$(call build-chart,provider-vsphere,https://github.com/kubernetes-sigs/cluster-api-provider-vsphere//config/default,$(PROVIDER_VSPHERE_VERSION))
	$(call fix-crds,provider-vsphere)
	@find provider-vsphere/crds -type f -exec $(SED) -i -e 's#capi-capi-#capi-#g' {} \;
	@find provider-vsphere/templates -type f -exec $(SED) -i -e 's#secretName: capv-webhook-service-cert#secretName: capi-capv-webhook-service-cert#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_VSPHERE_VERSION)"' provider-vsphere/values.yaml
	@yq -i '.fullnameOverride="capi-capi-provider-vsphere"' provider-vsphere/values.yaml
	@yq -i '.version="0.0.2"' provider-vsphere/Chart.yaml

build-provider-ipam:
	$(call build-chart,provider-ipam,https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/default,$(PROVIDER_IPAM_VERSION))
	$(call fix-crds,provider-ipam)
	@find provider-ipam/crds -type f -exec $(SED) -i -e 's#capi-capi-#capi-#g' {} \;
	@find provider-ipam/templates -type f -exec $(SED) -i -e 's#capi-capi-#capi-#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_IPAM_VERSION)"' provider-ipam/values.yaml
	@yq -i '.fullnameOverride="capi-capi-provider-ipam"' provider-ipam/values.yaml
	@yq -i '.version="0.1.1"' provider-ipam/Chart.yaml

build-ipam-capi-remote:
	@rm -rf ipam-capi-remote
	@cat kustomize/ipam-capi-remote/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir ipam-capi-remote
	@cp kustomize/ipam-capi-remote/remote-kubeconfig.yaml ipam-capi-remote/templates
	@cp kustomize/ipam-capi-remote/managedresource.yaml ipam-capi-remote/templates
	@mkdir ipam-capi-remote/managedresources
	@kubectl kustomize kustomize/ipam-capi-remote-managedresources > ipam-capi-remote/managedresources/kustomize.yaml
	@cp kustomize/ipam-capi-remote-managedresources/rbac.yaml ipam-capi-remote/managedresources
	@cp kustomize/ipam-capi-remote-managedresources/globalinclusterippool.yaml ipam-capi-remote/managedresources
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_IPAM_VERSION)"' ipam-capi-remote/values.yaml
	@yq -i '.fullnameOverride="ipam-capi"' ipam-capi-remote/values.yaml
	@yq -i '.version="1.1.0"' ipam-capi-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' ipam-capi-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' ipam-capi-remote/managedresources/kustomize.yaml

build-provider-metal3:
	$(call build-chart,provider-metal3,https://github.com/metal3-io/cluster-api-provider-metal3//config/default,$(PROVIDER_METAL3_VERSION))
	$(call fix-crds,provider-metal3)
	@# hacky fix for ipam
	@find provider-metal3/crds -type f -exec $(SED) -i -e 's#capm3-system/#capi/#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#.capm3-system.#.capi.#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#/{{ include "provider-metal3.fullname" . }}-system/#/#g' {} \;
	@# fix for "no matches for kind "IPClaim" 
	@curl -sSL https://raw.githubusercontent.com/metal3-io/ip-address-manager/$(PROVIDER_METAL3_VERSION)/config/crd/bases/ipam.metal3.io_ipclaims.yaml -o provider-metal3/crds/ipam.metal3.io_ipclaims.yaml
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL3_VERSION)"' provider-metal3/values.yaml
	@yq -i '.fullnameOverride="capm3"' provider-metal3/values.yaml
	@yq -i '.version="1.0.0"' provider-metal3/Chart.yaml

build-provider-metal:
	$(call build-chart,provider-metal,https://github.com/ironcore-dev/cluster-api-provider-ironcore-metal//config/default,$(PROVIDER_METAL_VERSION))
	$(call fix-crds,provider-metal)
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL_VERSION)"' provider-metal/values.yaml
	@yq -i '.fullnameOverride="provider-metal"' provider-metal/values.yaml
	@yq -i '.version="0.1.0"' provider-metal/Chart.yaml

build-provider-kubernikus:
	$(call build-chart,provider-kubernikus,https://github.com/sapcc/cluster-api-control-plane-provider-kubernikus//config/default,$(PROVIDER_KUBERNIKUS_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_KUBERNIKUS_VERSION)"' provider-kubernikus/values.yaml
	@yq -i '.fullnameOverride="capi-cp-provider-kubernikus"' provider-kubernikus/values.yaml
	@yq -i '.version="0.2.0"' provider-kubernikus/Chart.yaml

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
	@yq -i '.version="1.1.0"' baremetal-operator-core/Chart.yaml

build-metal-operator-remote:
	@helm dep up metal-operator-remote
	@helm template metal-operator metal-operator-remote/charts/metal-operator* \
		-n kube-system \
		-f metal-operator-remote/values-managed-resources.yaml |\
		$(SED) 's/kind: Role/kind: ClusterRole/g' - |\
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration")' - >\
		metal-operator-remote/managedresources/crds-and-rbac.yaml
	yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' metal-operator-remote/Chart.yaml

build-boot-operator-remote:
	@helm dep up boot-operator-remote
	@helm template boot-operator boot-operator-remote/charts/boot-operator* \
		-n kube-system \
		-f boot-operator-remote/values-managed-resources.yaml |\
		$(SED) 's/kind: Role/kind: ClusterRole/g' - |\
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration")' - >\
		boot-operator-remote/managedresources/crds-and-rbac.yaml
	yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' boot-operator-remote/Chart.yaml

build-argora-operator:
	@helm dep up argora-operator
	@yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' argora-operator/Chart.yaml

build-argora-operator-remote:
	@helm dep up argora-operator-remote
	@helm template argora-operator argora-operator-remote/charts/argora-* \
		-n kube-system \
		-f argora-operator-remote/values-managed-resources.yaml |\
		$(SED) 's/kind: Role/kind: ClusterRole/g' - |\
		yq eval 'select(.kind != "Service" and .kind != "ValidatingWebhookConfiguration" and .kind != "ConfigMap" and .kind != "Secret")' - >\
		argora-operator-remote/managedresources/crds-and-rbac.yaml
		yq -i '.version = (.version | split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' argora-operator-remote/Chart.yaml

build-khalkeon-remote:
	@helm template khalkeon khalkeon-remote/charts/khalkeon* \
		-f khalkeon-remote/values.yaml \
		-f khalkeon-remote/values-managed-resources.yaml |\
		$(SED) 's/kind: Role/kind: ClusterRole/g' - |\
		yq eval 'select(.kind != "Service")' - >\
		khalkeon-remote/managedresources/crds-and-rbac.yaml

# chart name, source url, tag
define build-chart
@echo "Generating Helm chart for $(1) version $(3)"
@ yq -i '.resources[0] = "$(2)?ref=$(3)"' kustomization.yaml
@rm -rf $(1)
@kubectl kustomize | helmify -crd-dir $(1)
@$(SED) -i -E 's/\$$\{[^:=]+\:=([^}]+)\}/\1/g' $(1)/values.yaml
@yq -i '.appVersion="$(3)"' $(1)/Chart.yaml
@git restore kustomization.yaml
endef

# chart name
define fix-crds
@echo "Fixing webhook certs for $(1)"
@# delete pre-filled caBundle
@find $(1)/crds -type f | xargs -n1 yq -i 'del(.spec.conversion.webhook.clientConfig.caBundle)'
@find $(1)/crds -type f | xargs -n1 yq -i 'del(.metadata.creationTimestamp)'
endef
