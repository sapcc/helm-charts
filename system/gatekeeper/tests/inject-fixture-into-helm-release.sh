#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")" || exit 1

if [[ $# == 0 ]]; then
echo "Usage: ./inject-fixture-into-helm-release.sh helm-release.in.yaml"
fi

fixture="$1"

helm_release=almost-empty-chart/helm-release.yaml
template="$(yq '.template' "$fixture")"
template_base64='| .chart.templates[].data = "'"$(echo "$template" | base64 -w0)"'" |  .manifest = "'"$template"'"'

while read -r line; do
  # set both .chart.values and .config to emulate subcharts
  values+="| .chart.values.$line | .config.$line"
done < <(yq '.values[] | to_entries | .[] | .key + " = \"" + .value + "\""' "$fixture")

yq '. | .data.release = "'"$(yq .data.release "$helm_release" | base64 -d | base64 -d | gunzip | jq ". ${values:-} $template_base64" | gzip | base64 -w0 | base64 -w0)"'"' "$helm_release"
