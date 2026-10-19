GENERATED_FIXTURES=$(patsubst %.in.yaml,%.out.yaml,$(wildcard tests/fixtures/*/*.in.yaml))

default: check

prepare: FORCE
	@if ! hash doop-image-checker 2>/dev/null; then printf "\e[1;36m>> Installing doop-image-checker (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/doop-image-checker@latest; fi
	@if ! hash gator 2>/dev/null; then printf "\e[1;36m>> Installing gator (this may take a while)...\e[0m\n"; go install github.com/open-policy-agent/gatekeeper/v3/cmd/gator@latest; fi
	@if ! hash helm-manifest-generator 2>/dev/null; then printf "\e[1;36m>> Installing helm-manifest-generator (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/helm-manifest-generator@latest; fi
	@if ! hash helm-manifest-parser 2>/dev/null; then printf "\e[1;36m>> Installing helm-manifest-parser (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/helm-manifest-parser@latest; fi

check: FORCE $(GENERATED_FIXTURES) prepare
	bash ./tests/run.sh

trace: FORCE $(GENERATED_FIXTURES) prepare
	@# Warning: This produces *a lot* of output. The traces can help in debugging Rego-level issues,
	@# but the trace output should not be enabled by default (e.g. in CI).
	bash ./tests/run.sh --trace

%.out.yaml: %.in.yaml prepare
	helm-manifest-generator < $< > $@

FORCE:
