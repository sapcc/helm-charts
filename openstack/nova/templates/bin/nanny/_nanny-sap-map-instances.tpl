#!/usr/bin/env bash
set -euo pipefail

echo "INFO: fixing inconsistenties in db table 'instance_mappings' with batch size " \
  "{{ .Values.nanny.sap_map_instances.max_rows }}"
nova-manage sap map_instances --all-cells --verbose \
  --max_rows {{ .Values.nanny.sap_map_instances.max_rows }}
