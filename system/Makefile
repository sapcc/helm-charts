CLUSTER_API_VERSION ?= v1.6.2
PROVIDER_METAL3_VERSION ?= v1.6.0
PROVIDER_KUBERNIKUS_VERSION ?= 5dd4e2434f25aa2561ec192cc45ba0332f0eafab

UNAME_S := $(shell uname -s)
SED := sed
ifeq ($(UNAME_S),Darwin)
    SED := gsed
endif

build: build-cluster-api-core build-bootstrap-kubeadm build-provider-metal3 build-provider-kubernikus

build-cluster-api-core:
	$(call build-chart,cluster-api-core,https://github.com/kubernetes-sigs/cluster-api//config/default,$(CLUSTER_API_VERSION))
	$(call fix-crd-certs,cluster-api-core,serving-cert)
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' cluster-api-core/values.yaml
	@yq -i '.version="0.1.1"' cluster-api-core/Chart.yaml

build-bootstrap-kubeadm:
	$(call build-chart,bootstrap-kubeadm,https://github.com/kubernetes-sigs/cluster-api//bootstrap/kubeadm/config/default,$(CLUSTER_API_VERSION))
	$(call fix-crd-certs,bootstrap-kubeadm,serving-cert)
	@yq -i '.controllerManager.manager.image.tag="$(CLUSTER_API_VERSION)"' bootstrap-kubeadm/values.yaml
	@yq -i '.version="0.1.1"' bootstrap-kubeadm/Chart.yaml

build-provider-metal3:
	$(call build-chart,provider-metal3,https://github.com/metal3-io/cluster-api-provider-metal3//config/default,$(PROVIDER_METAL3_VERSION))
	@# a bit hacky, since the kustomize provision two certs for different conversion webhooks
	$(call fix-crd-certs,provider-metal3,capm3-serving-cert)
	@yq -i '.capm3ControllerManager.manager.image.tag="$(PROVIDER_METAL3_VERSION)",.ipamControllerManager.manager.image.tag="$(PROVIDER_METAL3_VERSION)"' provider-metal3/values.yaml
	@yq -i '.version="0.1.1"' provider-metal3/Chart.yaml

build-provider-kubernikus:
	$(call build-chart,provider-kubernikus,https://github.com/sapcc/cluster-api-control-plane-provider-kubernikus//config/default,$(PROVIDER_KUBERNIKUS_VERSION))
	@yq -i '.controllerManager.manager.image.tag="$(PROVIDER_KUBERNIKUS_VERSION)"' provider-kubernikus/values.yaml
	@yq -i '.version="0.1.3"' provider-kubernikus/Chart.yaml

# chart name, source url, tag
define build-chart
@echo "Generating Helm chart for $(1) version $(3)"
@rm -rf $(1)
@kubectl kustomize "$(2)?ref=$(3)" | helmify -crd-dir $(1)
@$(SED) -i -E 's/\$$\{[^:=]+\:=([^}]+)\}/\1/g' $(1)/values.yaml
@yq -i '.appVersion="$(3)"' $(1)/Chart.yaml
endef

# chart name, cert name
define fix-crd-certs
@echo "Fixing webhook certs for $(1)"
@# delete pre-filled caBundle
@find $(1)/crds -type f | xargs -n1 yq -i 'del(.spec.conversion.webhook.clientConfig.caBundle)'
@# add cert-manager annotation, when .spec.conversion.webhook.clientConfig exists
@# also requires all charts to be installed with a parent chart releas named cluster-api in capi namespace
@# (one cannot template in crds)
@find $(1)/crds -type f | xargs -n1 yq -i 'with(select(.spec.conversion.webhook.clientConfig); .metadata.annotations."cert-manager.io/inject-ca-from" = "capi/cluster-api-$(1)-$(2)")'
endef
