#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC1091
# shellcheck disable=SC2250
# shellcheck disable=SC2321
set -o pipefail
set -u

source /usr/bin/common-functions.sh

MYSQL_ADDRESS=${MYSQL_ADDRESS:-""}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

if [[ -z "${MYSQL_USER}" ]] || [[ -z "${MYSQL_ADDRESS}" ]] || [[ -z "${MYSQL_PASSWORD}" ]]; then
    logerror "check_env" "Required environment variables are not set (MYSQL_USER, MYSQL_ADDRESS, MYSQL_PASSWORD)"
    exit 1
fi

export MYSQL_PWD="${MYSQL_PASSWORD}"

check_connection() {
    local max_attempts=12
    local wait_time=10
    local attempt=1

    while [[ $attempt -le "${max_attempts}" ]]; do
        if mysql -h"${MYSQL_ADDRESS}" -u"${MYSQL_USER}" -e "SELECT 1" >/dev/null 2>&1; then
            loginfo "check_connection" "Database connection successful on attempt ${attempt}"
            return 0
        else
            logerror "check_connection" "Connection attempt ${attempt}/${max_attempts} failed, waiting ${wait_time} seconds..."
            sleep "${wait_time}"
            attempt=$((attempt + 1))
        fi
    done

    logerror "check_connection" "Failed to connect to MariaDB server after ${max_attempts} attempts"
    return 1
}

if ! check_connection; then
    exit 1
fi

get_databases() {
    mysql -h"${MYSQL_ADDRESS}" -u"${MYSQL_USER}" -N -e "
        SELECT SCHEMA_NAME
        FROM information_schema.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys', 'innodb');"
}

get_constraints() {
    local db=$1
    mysql -h"${MYSQL_ADDRESS}" -u"${MYSQL_USER}" "${db}" -N -e "
        SELECT
            TABLE_NAME,
            CONSTRAINT_NAME,
            CHECK_CLAUSE
        FROM
            information_schema.CHECK_CONSTRAINTS
        WHERE
            CONSTRAINT_SCHEMA = DATABASE()
            AND CONSTRAINT_NAME LIKE 'CONSTRAINT_%'
        ORDER BY
            TABLE_NAME, CONSTRAINT_NAME;"
}

generate_sql() {
    local db=$1
    local output_file=$2

    local current_table=""
    local counter=1

    while read -r table constraint check_clause; do
        if [[ "${table}" != "${current_table}" ]]; then
            current_table="${table}"
            counter=1
        fi

        local new_constraint="${table}_chk_${counter}"
        echo "ALTER TABLE \`$db\`.\`$table\` DROP CONSTRAINT \`$constraint\`, ADD CONSTRAINT \`$new_constraint\` CHECK($check_clause);" >> "${output_file}"
        ((counter++))
    done < <(get_constraints "$db")
}

execute_sql() {
    local sql_file=$1
    if [[ -s "${sql_file}" ]]; then
        loginfo "execute_sql" "Executing check constraint rename operations..."
        if mysql -h"${MYSQL_ADDRESS}" -u"${MYSQL_USER}" < "${sql_file}"; then
            loginfo "execute_sql" "Check constraint rename operations completed."
            return 0
        else
            logerror "execute_sql" "Check constraint rename operations failed."
            return 1
        fi
    else
        loginfo "execute_sql" "No check constraint rename operations to execute."
        return 0
    fi
}

main() {
    local sql_file="/tmp/rename_constraints.sql"
    : > "${sql_file}"
    trap 'rm -f "${sql_file}"' EXIT HUP INT TERM

    local count=0

    for db in $(get_databases); do
        loginfo "main" "Processing database: $db"
        generate_sql "${db}" "${sql_file}"

        local constraint_count
        constraint_count=$(grep -c "ALTER TABLE \`$db\`\." "${sql_file}")

        if [[ "${constraint_count}" -gt 0 ]]; then
            loginfo "main" "Found ${constraint_count} check constraints in ${db}"
            count=$((count + constraint_count))
        fi
    done

    if [[ "${count}" -gt 0 ]]; then
        loginfo "main" "Found ${count} total check constraints to rename."
        if execute_sql "${sql_file}"; then
            loginfo "main" "Check constraint rename operations completed."
        else
            logerror "main" "Check constraint rename operations failed."
        fi
    else
        loginfo "main" "No matching check constraints found in any database."
    fi

    rm -f "${sql_file}"
    trap - EXIT HUP INT TERM
}

main
