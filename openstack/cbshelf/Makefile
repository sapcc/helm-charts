VAULT_QA=--set vault.certKey="$$(vault read --field=data -format=json  secrets/data/s-qa-de-1/cronus/cbshelf | jq -r ".certKey" )" \
	--set vault.dbPassword="$$(vault read --field=data -format=json  secrets/data/s-qa-de-1/cronus/cbshelf | jq -r ".dbPassword" )" \
	--set vault.railsSecret="$$(vault read --field=data -format=json  secrets/data/s-qa-de-1/cronus/cbshelf | jq -r ".railsSecret" )"

template-qa:
	helm template --debug --force . --values ./env/qa-de-1.yaml $(VAULT_QA)
install-qa:
	helm upgrade --namespace=cbshelf --create-namespace -i shelfapp . --values ./env/qa-de-1.yaml $(VAULT_QA)
