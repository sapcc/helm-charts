GENERATED_FIXTURES=$(patsubst %.in.yaml,%.out.yaml,$(wildcard tests/fixtures/*/*.in.yaml))

check: FORCE $(GENERATED_FIXTURES)
	./tests/run.sh

trace: FORCE $(GENERATED_FIXTURES)
	@# Warning: This produces *a lot* of output. The traces can help in debugging Rego-level issues,
	@# but the trace output should not be enabled by default (e.g. in CI).
	./tests/run.sh --trace

tests/%.out.yaml: tests/%.in.yaml
	helm-manifest-generator < $< > $@

FORCE:
