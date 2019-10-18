#!/bin/bash

HELM_CHARTS=$(cd $( dirname "${BASH_SOURCE[0]}" )/..; echo $PWD)

if [ ! -f "$HELM_CHARTS/$1/Chart.yaml" ]; then
  echo usage: $0 CHART_DIRECTORY
  exit 1
fi

docker run --rm -v $HELM_CHARTS:/charts -w /charts sapcc/chart-testing:v2.3.3-sapcc  ct lint \
  --chart-yaml-schema ci/chart_schema.yaml \
  --lint-conf ci/lintconf.yaml \
  --config ci/config.yaml --charts $1
