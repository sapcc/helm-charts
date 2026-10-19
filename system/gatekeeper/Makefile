default: check

install-doop-analyzer: FORCE
	@if ! hash doop-analyzer 2>/dev/null; then printf "\e[1;36m>> Installing doop-analyzer (this may take a while)...\e[0m\n"; go install github.com/sapcc/gatekeeper-addons/doop-analyzer@latest; fi

check: check-doop-analyzer-rules check-gatekeeper-policies

check-doop-analyzer-rules: FORCE render-charts install-doop-analyzer
	./tests/doop-analyzer-rules/run.sh

check-gatekeeper-policies: FORCE render-charts
	./tests/check-gatekeeper-policies.sh

render-charts: FORCE
	@# just to be safe from stupid mistakes because an old chart version cached
	helm dep up
	./tests/render-charts.sh

FORCE:
