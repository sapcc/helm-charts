HELM ?= helm

check: FORCE
	$(HELM) dep up && $(HELM) template gatekeeper . --values ci/test-values.yaml --output-dir tests/rendered-chart
	cd ../gatekeeper-config && $(HELM) dep up && $(HELM) template gatekeeper-config . --values ci/test-values.yaml --output-dir ../gatekeeper/tests/rendered-chart
	cd tests && gator verify -v .

FORCE:
