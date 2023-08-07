GENERATED_FIXTURES=$(patsubst %.in.yaml,%.out.yaml,$(wildcard tests/gatekeeper-policies/fixtures/*/*.in.yaml))

check: check-gatekeeper-policies

check-gatekeeper-policies: FORCE render-charts $(GENERATED_FIXTURES)
	./tests/gatekeeper-policies/run.sh

trace-gatekeeper-policies: FORCE render-charts $(GENERATED_FIXTURES)
	@# Warning: This produces *a lot* of output. The traces can help in debugging Rego-level issues,
	@# but the trace output should not be enabled by default (e.g. in CI).
	./tests/gatekeeper-policies/run.sh --trace

tests/%.out.yaml: tests/%.in.yaml
	helm-manifest-generator < $< > $@

render-charts: FORCE
	./tests/render-charts.sh

FORCE:
