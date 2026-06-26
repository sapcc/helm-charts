#!/usr/bin/env bash
set -euo pipefail

echo "INFO: soft-deleting db rows exceeding {{ .Values.nanny.db_soft_delete_excessive_instance_faults.max_faults }} " \
  "instance faults per instance with batch size {{ .Values.nanny.db_soft_delete_excessive_instance_faults.max_rows }}"

# Command "nova-manage db delete_excessive_instance_faults" returns exit code 1
# if rows were soft-deleted. Catch this to prevent job failure.
nova-manage db soft_delete_excessive_instance_faults --until-complete \
  --max_rows {{ .Values.nanny.db_soft_delete_excessive_instance_faults.max_rows }} --all-cells --verbose \
  --max_faults {{ .Values.nanny.db_soft_delete_excessive_instance_faults.max_faults }} || [[ "$?" == "1" ]]
