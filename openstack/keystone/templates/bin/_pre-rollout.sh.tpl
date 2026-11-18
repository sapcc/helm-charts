#!/usr/bin/env bash

config=(--config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf)
check_config=("${config[@]}" --config-file=/etc/keystone/keystone.conf.d/upgrade-check.conf)
manage=(keystone-manage "${config[@]}")

run_step() {
    local step=$1
    shift
    echo "Running $step"
    "$@"
    local status=$?
    if [[ "$status" != 0 ]]; then
        echo "ERROR: $step failed with exit code $status." >&2
    fi
    return "$status"
}

pre_rollout() {
    # kubernetes-entrypoint handles migration ordering.
    # Accept a current schema (0) or expansion with contraction pending (4).
    local status=0
    keystone-manage "${check_config[@]}" db_sync --check || status=$?
    if [[ "$status" != 0 && "$status" != 4 ]]; then
        echo "ERROR: Database expansion has not completed (schema check: $status)." >&2
        return "$status"
    fi

    run_step "native Keystone bootstrap" "${manage[@]}" bootstrap \
        --bootstrap-username {{ .Values.api.adminUser }} \
        --bootstrap-password {{ required "A valid .Values.api.adminPassword required!" .Values.api.adminPassword | include "resolve_secret" }} \
        --bootstrap-project-name {{ .Values.api.adminProjectName }} \
{{- if eq .Values.services.admin.scheme "https" }}
        --bootstrap-admin-url https://{{.Values.services.admin.host}}.{{.Values.global.region}}.{{.Values.global.tld}}/v3 \
{{- else }}
        --bootstrap-admin-url {{.Values.services.admin.scheme}}://{{.Values.services.admin.host}}.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
{{- end }}
{{- if eq .Values.services.public.scheme "https" }}
        --bootstrap-public-url https://{{.Values.services.public.host}}.{{.Values.global.region}}.{{.Values.global.tld}}/v3 \
{{- else }}
        --bootstrap-public-url {{.Values.services.public.scheme}}://{{.Values.services.public.host}}.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3 \
{{- end }}
{{- if .Values.global.is_global_region }}
        --bootstrap-internal-url http://{{ .Values.global.keystone_internal_ip }}:5000/v3 \
{{- else }}
        --bootstrap-internal-url http://{{ include "keystone_api_endpoint_host_internal" . }}:5000/v3 \
{{- end }}
        --bootstrap-region-id {{ .Values.global.region }} || return $?

    # TODO(habetuz): Allow bootstrap to fail script once we are certain it is working and stable.
    # Run additional bootstrap tasks previously handled by seeders.
    run_step "Keystone extensions bootstrap" keystone-manage-extension "${config[@]}" bootstrap \
        --bootstrap-file=/etc/keystone/bootstrap.yaml || echo "WARNING: Extension bootstrap failed with exit code $?; continuing..."

    run_step "credential migration" "${manage[@]}" credential_migrate \
        --keystone-user keystone --keystone-group keystone || return $?

    echo "Keystone doctor:"
    # TODO(habetuz): Keep doctor diagnostic-only until '--ignore' is available to ignore unimportant checks.
    keystone-manage "${check_config[@]}" doctor || true

    echo "Checking the upgraded API against the prepared database."
    status=0
    keystone-status "${check_config[@]}" upgrade check || status=$?
    case "$status" in
        0) ;;
        1) echo "WARNING: Keystone upgrade check reported warnings; continuing." >&2 ;;
        *) echo "ERROR: Keystone upgrade check failed ($status); API will not start." >&2; return "$status" ;;
    esac
}

pre_rollout
status=$?
{{ include "utils.script.job_finished_hook" . | trim }}
exit "$status"
