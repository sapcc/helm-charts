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
