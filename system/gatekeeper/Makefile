GENERATED_FIXTURES=$(patsubst %.in.yaml,%.out.yaml,$(wildcard tests/gatekeeper-policies/fixtures/*/*.in.yaml))

default: check

install-doop-analyzer: FORCE
	@if ! hash doop-analyzer 2>/dev/null; then printf "\e[1;36m>> Installing doop-analyzer (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/doop-analyzer@latest; fi

install-doop-image-checker: FORCE
	@if ! hash doop-image-checker 2>/dev/null; then printf "\e[1;36m>> Installing doop-image-checker (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/doop-image-checker@latest; fi

install-gator: FORCE
	@if ! hash gator 2>/dev/null; then printf "\e[1;36m>> Installing gator (this may take a while)...\e[0m\n"; go install github.com/open-policy-agent/gatekeeper/v3/cmd/gator@latest; fi

install-helm-manifest-generator: FORCE
	@if ! hash helm-manifest-generator 2>/dev/null; then printf "\e[1;36m>> Installing helm-manifest-generator (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/helm-manifest-generator@latest; fi

install-helm-manifest-parser: FORCE
	@if ! hash helm-manifest-parser 2>/dev/null; then printf "\e[1;36m>> Installing helm-manifest-parser (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/helm-manifest-parser@latest; fi

check: check-doop-analyzer-rules check-gatekeeper-policies

check-doop-analyzer-rules: FORCE render-charts install-doop-analyzer
	./tests/doop-analyzer-rules/run.sh

check-gatekeeper-policies: FORCE render-charts $(GENERATED_FIXTURES) install-doop-image-checker install-gator install-helm-manifest-parser
	./tests/gatekeeper-policies/run.sh

trace-gatekeeper-policies: FORCE render-charts $(GENERATED_FIXTURES)
	@# Warning: This produces *a lot* of output. The traces can help in debugging Rego-level issues,
	@# but the trace output should not be enabled by default (e.g. in CI).
	./tests/gatekeeper-policies/run.sh --trace

tests/%.out.yaml: tests/%.in.yaml install-helm-manifest-generator
	helm-manifest-generator < $< > $@

render-charts: FORCE
	@# just to be safe from stupid mistakes because an old chart version cached
	helm dep up
	./tests/render-charts.sh

FORCE:
