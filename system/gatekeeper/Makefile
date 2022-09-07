GENERATED_FIXTURES=$(patsubst %.in.yaml,%.out.yaml,$(wildcard tests/fixtures/*/*.in.yaml))

check: FORCE $(GENERATED_FIXTURES)
	./tests/run.sh

tests/%.out.yaml: tests/%.in.yaml tests/inject-fixture-into-helm-release.sh
	cd ./tests && ./inject-fixture-into-helm-release.sh $*.in.yaml > $*.out.yaml

FORCE:
