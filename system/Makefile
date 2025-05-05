CLUSTER_API_VERSION ?= v1.10.1
PROVIDER_METAL3_VERSION ?= v1.10.0
PROVIDER_METAL_VERSION ?= 00d028c4aac7fa1e168c5ec9fab74e197530e37c
PROVIDER_VSPHERE_VERSION ?= v1.9.3
PROVIDER_IPAM_VERSION ?= v0.1.1
PROVIDER_KUBERNIKUS_VERSION ?= 9fd81475b828971913b3b27addf51fdbd0511d85
BAREMETAL_OPERATOR_VERSION ?= v0.6.0
METAL_OPERATOR_VERSION ?= d339e4ef08f0c3208a9d6c9b46c0a5a9b7266a6c
BOOT_OPERATOR_VERSION ?= e719a1651befdf1b84904c4644a57597d7022186
IPXE_OPERATOR_VERSION ?= 61c6898bfd7772008835bdcca8d8a64c1dfc3b32
FEDHCP_VERSION ?= a59539c62aaa11a96c82fe792c87daaac4cb75bf
IPAM_VERSION ?= 6faf501000c5d7ff9744a3c111ca5ecf3339c00c
ARGORA_VERSION ?= 06b8e140698d509b98376b22f0e06d1dddf51431

SHELL := bash
.ONESHELL:

UNAME_S := $(shell uname -s)
SED := sed
ifeq ($(UNAME_S),Darwin)
    SED := gsed
endif

build: build-cluster-api-core build-bootstrap-kubeadm build-provider-metal3 build-provider-kubernikus

build-cluster-api-core:
	$(call build-chart,cluster-api-core,https://github.com/kubernetes-sigs/cluster-api//config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,cluster-api-core)
	@find cluster-api-core/crds -type f -exec $(SED) -i -e 's#capi-system#capi#g' {} \;
	@find cluster-api-core/templates -type f -exec $(SED) -i -e 's#/{{ include "cluster-api-core.fullname" . }}-system/#/#g' {} \;
	@find cluster-api-core/templates -type f -exec $(SED) -i -e 's#-system.#.#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' cluster-api-core/values.yaml
	@yq -i '.fullnameOverride="capi"' cluster-api-core/values.yaml
	@yq -i '.version="0.2.1"' cluster-api-core/Chart.yaml

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
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' controlplane-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-controlplane"' controlplane-kubeadm/values.yaml
	@yq -i '.version="0.2.1"' controlplane-kubeadm/Chart.yaml

build-bootstrap-kubeadm:
	$(call build-chart,bootstrap-kubeadm,https://github.com/kubernetes-sigs/cluster-api//bootstrap/kubeadm/config/default,$(CLUSTER_API_VERSION))
	$(call fix-crds,bootstrap-kubeadm)
	@find bootstrap-kubeadm/crds -type f -exec $(SED) -i -e 's#capi-kubeadm-bootstrap-system#capi#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#/{{ include "bootstrap-kubeadm.fullname" . }}-system/#/#g' {} \;
	@find bootstrap-kubeadm/templates -type f -exec $(SED) -i -e 's#-kubeadm-bootstrap-system.#.#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' bootstrap-kubeadm/values.yaml
	@yq -i '.fullnameOverride="capi-kubeadm-bootstrap"' bootstrap-kubeadm/values.yaml
	@yq -i '.version="0.2.1"' bootstrap-kubeadm/Chart.yaml

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
	@yq -i '.version="0.0.3"' provider-ipam/Chart.yaml

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
	@yq -i '.version="1.0.3"' ipam-capi-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' ipam-capi-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' ipam-capi-remote/managedresources/kustomize.yaml

build-provider-metal3:
	$(call build-chart,provider-metal3,https://github.com/metal3-io/cluster-api-provider-metal3//config/default,$(PROVIDER_METAL3_VERSION))
	$(call fix-crds,provider-metal3)
	@# hacky fix for ipam
	@find provider-metal3/crds -type f -exec $(SED) -i -e 's#capm3-system/#capi/#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#.capm3-system.#.capi.#g' {} \;
	@find provider-metal3/templates -type f -exec $(SED) -i -e 's#/{{ include "provider-metal3.fullname" . }}-system/#/#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL3_VERSION)"' provider-metal3/values.yaml
	@yq -i '.fullnameOverride="capm3"' provider-metal3/values.yaml
	@yq -i '.version="0.2.5"' provider-metal3/Chart.yaml

build-provider-metal:
	$(call build-chart,provider-metal,https://github.com/ironcore-dev/cluster-api-provider-ironcore-metal//config/default,$(PROVIDER_METAL_VERSION))
	$(call fix-crds,provider-metal)
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_METAL_VERSION)"' provider-metal/values.yaml
	@yq -i '.fullnameOverride="provider-metal"' provider-metal/values.yaml
	@yq -i '.version="0.0.7"' provider-metal/Chart.yaml

build-provider-kubernikus:
	$(call build-chart,provider-kubernikus,https://github.com/sapcc/cluster-api-control-plane-provider-kubernikus//config/default,$(PROVIDER_KUBERNIKUS_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_KUBERNIKUS_VERSION)"' provider-kubernikus/values.yaml
	@yq -i '.fullnameOverride="capi-cp-provider-kubernikus"' provider-kubernikus/values.yaml
	@yq -i '.version="0.1.8"' provider-kubernikus/Chart.yaml

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
	@yq -i '.version="1.0.1"' baremetal-operator-core/Chart.yaml

build-metal-operator:
	@cat kustomize/metal-operator/kustomization.yaml >> kustomization.yaml
	$(call build-chart,metal-operator-core,https://github.com/ironcore-dev/metal-operator//config/default,$(METAL_OPERATOR_VERSION))
	$(call fix-crds,metal-operator-core)
	@find metal-operator-core/crds -type f -exec $(SED) -i -e 's#metal-operator-metal-operator-#metal-#g' {} \;
	@find metal-operator-core/crds -type f -exec $(SED) -i -e 's#metal-webhook-service#metal-operator-webhook-service#g' {} \;
	@find metal-operator-core/templates -type f -exec $(SED) -i -e 's#{{ include "metal-operator-core.fullname" . }}-metal-#metal-#g' {} \;
	@find metal-operator-core/templates -type f -exec $(SED) -i -e 's#metal-serving-#metal-operator-serving-#g' {} \;
	@find metal-operator-core/templates -type f -exec $(SED) -i -e 's#metal-webhook-service#metal-operator-webhook-service#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(METAL_OPERATOR_VERSION)"' metal-operator-core/values.yaml
	@yq -i '.fullnameOverride="metal-operator"' metal-operator-core/values.yaml
	@yq -i '.version="1.1.4"' metal-operator-core/Chart.yaml

build-metal-operator-remote:
	@rm -rf metal-operator-remote
	@cat kustomize/metal-operator-remote/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir metal-operator-remote
	@cp kustomize/metal-operator-remote/remote-kubeconfig.yaml metal-operator-remote/templates
	@cp kustomize/metal-operator-remote/rotate-kubeconfig.yaml metal-operator-remote/templates
	@cp kustomize/metal-operator-remote/managedresource.yaml metal-operator-remote/templates
	@cp kustomize/metal-operator-remote/macdb.yaml metal-operator-remote/templates
	@mkdir metal-operator-remote/managedresources
	@kubectl kustomize kustomize/metal-operator-managedresources > metal-operator-remote/managedresources/kustomize.yaml
	@cp kustomize/metal-operator-managedresources/rbac.yaml metal-operator-remote/managedresources
	@yq -i '.controllerManager.manager.image.tag="$(METAL_OPERATOR_VERSION)"' metal-operator-remote/values.yaml
	@yq -i '.fullnameOverride="metal-operator"' metal-operator-remote/values.yaml
	@yq -i '.remote.ca=""' metal-operator-remote/values.yaml
	@echo 'macdb: {}' >> metal-operator-remote/values.yaml
	@mkdir metal-operator-remote/ci
	@echo 'global:' >> metal-operator-remote/ci/test-values.yaml
	@echo '  region: ab-cd-1' >> metal-operator-remote/ci/test-values.yaml
	@yq -i '.version="0.3.10"' metal-operator-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' metal-operator-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' metal-operator-remote/managedresources/kustomize.yaml

build-boot-operator:
	@cat kustomize/boot-operator/kustomization.yaml >> kustomization.yaml
	$(call build-chart,boot-operator,https://github.com/ironcore-dev/boot-operator//config/default,$(BOOT_OPERATOR_VERSION))
	@find boot-operator/templates -type f -exec $(SED) -i -e 's#{{ include "boot-operator.fullname" . }}-boot-operator#boot-operator#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(BOOT_OPERATOR_VERSION)"' boot-operator/values.yaml
	@yq -i '.fullnameOverride="boot-operator"' boot-operator/values.yaml
	@yq -i '.version="1.0.5"' boot-operator/Chart.yaml

build-boot-operator-remote:
	@rm -rf boot-operator-remote
	@cat kustomize/boot-operator-remote/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir boot-operator-remote
	@cp kustomize/boot-operator-remote/remote-kubeconfig.yaml boot-operator-remote/templates
	@cp kustomize/boot-operator-remote/managedresource.yaml boot-operator-remote/templates
	@mkdir boot-operator-remote/managedresources
	@kubectl kustomize kustomize/boot-operator-managedresources > boot-operator-remote/managedresources/kustomize.yaml
	@yq -i '.controllerManager.manager.image.tag="$(BOOT_OPERATOR_VERSION)"' boot-operator-remote/values.yaml
	@yq -i '.fullnameOverride="boot-operator"' boot-operator-remote/values.yaml
	@yq -i '.version="0.3.1"' boot-operator-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' boot-operator-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' boot-operator-remote/managedresources/kustomize.yaml

build-ipxe-operator:
	@cat kustomize/ipxe-operator/kustomization.yaml >> kustomization.yaml
	$(call build-chart,ipxe-operator,https://github.com/ironcore-dev/ipxe-operator//config/default,$(IPXE_OPERATOR_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(BOOT_OPERATOR_VERSION)"' ipxe-operator/values.yaml
	@yq -i '.fullnameOverride="ipxe-operator"' ipxe-operator/values.yaml
	@yq -i '.version="0.0.8"' ipxe-operator/Chart.yaml

build-fedhcp:
	@cat kustomize/fedhcp/kustomization.yaml >> kustomization.yaml
	$(call build-chart,fedhcp,https://github.com/ironcore-dev/fedhcp//config/default,$(FEDHCP_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(FEDHCP_VERSION)"' fedhcp/values.yaml
	@yq -i '.fullnameOverride="fedhcp"' fedhcp/values.yaml
	@yq -i '.version="0.0.2"' fedhcp/Chart.yaml

build-ipam-operator:
	@cat kustomize/ipam-operator/kustomization.yaml >> kustomization.yaml
	$(call build-chart,ipam-operator,https://github.com/ironcore-dev/ipam//config/default,$(IPAM_VERSION))
	@find ipam-operator/crds -type f -exec $(SED) -i -e 's#ipam-system/ipam-serving-cert#ipam-system/ipam-operator-serving-cert#g' {} \;
	@find ipam-operator/templates -type f -exec $(SED) -i -e 's#-ipam-serving-cert#-serving-cert#g' {} \;
	@find ipam-operator/templates -type f -exec $(SED) -i -e 's#-ipam-webhook-service#-webhook-service#g' {} \;
	@yq -i '.controllerManager.manager.image.tag="$(IPAM_VERSION)"' ipam-operator/values.yaml
	@yq -i '.version="0.0.2"' ipam-operator/Chart.yaml

build-ipam-operator-remote:
	@rm -rf ipam-operator-remote
	@cat kustomize/ipam-operator-remote/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir ipam-operator-remote
	@cp kustomize/ipam-operator-remote/remote-kubeconfig.yaml ipam-operator-remote/templates
	@cp kustomize/ipam-operator-remote/managedresource.yaml ipam-operator-remote/templates
	@mkdir ipam-operator-remote/managedresources
	@kubectl kustomize kustomize/ipam-operator-managedresources > ipam-operator-remote/managedresources/kustomize.yaml
	@cp kustomize/ipam-operator-managedresources/rbac.yaml ipam-operator-remote/managedresources
	@cp kustomize/ipam-operator-managedresources/network.yaml ipam-operator-remote/managedresources
	@cp kustomize/ipam-operator-managedresources/subnet.yaml ipam-operator-remote/managedresources
	@yq -i '.controllerManager.manager.image.tag="$(IPAM_VERSION)"' ipam-operator-remote/values.yaml
	@yq -i '.fullnameOverride="ipam-operator"' ipam-operator-remote/values.yaml
	@yq -i '.version="0.2.2"' ipam-operator-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' ipam-operator-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' ipam-operator-remote/managedresources/kustomize.yaml

build-argora-operator:
	@cat kustomize/argora-operator/kustomization.yaml >> kustomization.yaml
	$(call build-chart,argora-operator,https://github.com/sapcc/argora//config/default,$(ARGORA_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(ARGORA_VERSION)"' argora-operator/values.yaml
	@yq -i '.fullnameOverride="argora-operator"' argora-operator/values.yaml
	@yq -i '.version="0.0.1"' argora-operator/Chart.yaml

build-argora-operator-remote:
	@rm -rf argora-operator-remote
	@cat kustomize/argora-operator-remote/kustomization.yaml > kustomization.yaml
	@kubectl kustomize | helmify -crd-dir argora-operator-remote
	@cp kustomize/argora-operator-remote/remote-kubeconfig.yaml argora-operator-remote/templates
	@cp kustomize/argora-operator-remote/managedresource.yaml argora-operator-remote/templates
	@mkdir argora-operator-remote/managedresources
	@kubectl kustomize kustomize/argora-operator-managedresources > argora-operator-remote/managedresources/kustomize.yaml
	@cp kustomize/argora-operator-managedresources/updates.yaml argora-operator-remote/managedresources
	@yq -i '.controllerManager.manager.image.tag="$(ARGORA_VERSION)"' argora-operator-remote/values.yaml
	@yq -i '.fullnameOverride="argora-operator"' argora-operator-remote/values.yaml
	@mkdir argora-operator-remote/ci
	@echo 'config:' >> argora-operator-remote/ci/test-values.yaml
	@echo '  configJson: {"serverController":"foo","ironCoreTypes":"bar","ironCoreRegion":"ab-cd-1","netboxURL":"https://foo.bar"}' >> argora-operator-remote/ci/test-values.yaml
	@echo 'secret:' >> argora-operator-remote/ci/test-values.yaml
	@echo '  credentialsJson: {"bmcUser":"foo","bmcPassword":"bar","netboxToken":"token"}' >> argora-operator-remote/ci/test-values.yaml
	@yq -i '.version="0.0.4"' argora-operator-remote/Chart.yaml
	@$(SED) -i 's/serviceAccountName.*$$/serviceAccountName: default/g' argora-operator-remote/templates/deployment.yaml
	@$(SED) -i 's/kind: Role/kind: ClusterRole/g' argora-operator-remote/managedresources/kustomize.yaml

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
