check: FORCE
	helm dep up && helm template gatekeeper . --values ci/test-values.yaml --output-dir tests/rendered-chart
	cd ../gatekeeper-config && helm dep up && helm template gatekeeper-config . --values ci/test-values.yaml --output-dir ../gatekeeper/tests/rendered-chart
	cd tests && gator verify -v .

FORCE:
