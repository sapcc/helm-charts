#!/bin/bash
set -uo pipefail
shopt -s nullglob

SECRETS_PATH="/etc/rabbitmq/secrets"

log() { echo "${1}: ${2}" >&2; }

read_file() {
    if [[ -f "${1}" ]]; then
        tr -d '\n\r' < "${1}"
    fi
}

user_exists() {
    local user="${1}" users="${2}"
    echo "${users}" | grep -qx "${user}"
}

manage_user() {
    local username="${1}" password="${2}" tag="${3}" users="${4}"

    if user_exists "${username}" "${users}"; then
        log INFO "Updating user: ${username}"
        rabbitmqctl change_password "${username}" <<< "${password}"
    else
        log INFO "Creating user: ${username}"
        rabbitmqctl add_user "${username}" <<< "${password}"
        rabbitmqctl set_permissions -p / "${username}" '.*' '.*' '.*'
    fi
    rabbitmqctl set_user_tags "${username}" "${tag}"
}

main() {
    log INFO "Starting RabbitMQ user setup"
    local errors=0 users

    users=$(rabbitmqctl list_users --quiet 2>/dev/null | awk '{print $1}')

    for file in "${SECRETS_PATH}"/user_*_username; do
        local base="${file%_username}" username password tag
        username=$(read_file "${file}")
        password=$(read_file "${base}_password")
        tag=$(read_file "${base}_tag")

        if [[ -z "${username}" ]]; then
            log ERROR "Empty username in ${file}"; ((errors++)); continue
        fi
        manage_user "${username}" "${password}" "${tag}" "${users}" || { log ERROR "Failed: ${username}"; ((errors++)); }
    done

    rabbitmqctl clear_password guest 2>/dev/null || { log ERROR "Failed to clear password for guest user"; ((errors++)); }

    if ((errors > 0)); then
        log WARN "${errors} user(s) failed to configure"
        [[ "${STRICT_MODE:-}" == "true" ]] && return 1
    fi
    log INFO "RabbitMQ user setup completed"
    return 0
}

main "$@"
