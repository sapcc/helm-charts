#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
audit_script="${script_dir}/../templates/bin/nanny/_nanny-placement-audit.tpl"

# Mock nova-manage: never contact Nova or Placement during this test.
nova-manage() {
  if [[ "$*" != "placement audit --verbose --delete" ]]; then
    echo "Unexpected nova-manage arguments: $*" >&2
    return 126
  fi
  return "${NOVA_MANAGE_EXIT_CODE}"
}
export -f nova-manage

for exit_code in 0 4 1 3 127; do
  export NOVA_MANAGE_EXIT_CODE="${exit_code}"
  script_exit_code=0
  bash "${audit_script}" || script_exit_code=$?

  if [[ "${exit_code}" == 0 || "${exit_code}" == 4 ]]; then
    if [[ "${script_exit_code}" != 0 ]]; then
      echo "Expected success for nova-manage exit code ${exit_code}" >&2
      exit 1
    fi
  elif [[ "${script_exit_code}" == 0 ]]; then
    echo "Expected failure for nova-manage exit code ${exit_code}" >&2
    exit 1
  fi
done

echo "Placement audit script: all exit-code cases passed."
