#!/usr/bin/env bash
set -eou pipefail

# Note:
# python yq and go yq don't have a combined flag for raw strings.
# go yq has it as default but not python yq

cd "$(dirname "$0")" || exit 1

if [[ $# == 0 ]]; then
echo "Usage: ./inject-fixture-into-helm-release.sh helm-release.in.yaml"
fi

fixture="$1"

helm_release=almost-empty-chart/helm-release.yaml
template="$(yq -r '.template' "$fixture")"
template_base64='| .chart.templates[].data = "'"$(echo "$template" | base64 -w0)"'" |  .manifest = "'"$template"'"'

while read -r line; do
  # split string like: .key.key = "value"
  # shellcheck disable=SC2206
  lineSplit=(${line// = / })
  keyUnquoted=${lineSplit[0]}
  key=""
  val=${lineSplit[1]}

  # manually require every part of the selector otherwise selectors like ".owner-info.support-group" are invalid
  # shellcheck disable=SC2206
  keySplit=(${keyUnquoted//./ })
  for item in "${keySplit[@]}"; do
    key+=".\"$item\""
  done

  # set both .chart.values and .config to emulate subcharts
  values+="| .chart.values$key = $val | .config$key = $val "
done < <(yq -r '.values | if type=="array" then .[] else [] end | to_entries[] | if (.value | type=="object") then .key + " = " + (.value|tostring) else .key + " = \"" + .value + "\"" end' "$fixture")

yq -r '. | .data.release = "'"$(yq -r .data.release "$helm_release" | base64 -d | base64 -d | gunzip | jq ". ${values:-} $template_base64" | gzip | base64 -w0 | base64 -w0)"'"' "$helm_release"
