#!/bin/bash

TMPDIR=${TMPDIR:-/tmp}
LAST_MYSQL_ERR=${TMPDIR}/migrate-mysql-db.err
MYSQLDUMP_FLAGS=${MYSQLDUMP_FLAGS:-"--extended-insert --single-transaction --skip-lock-tables --skip-add-locks --quick"}

declare -a ARGS
declare -a OPTS

function getflag() {
    # Return true if --$flag is present on the command line
    local flag="$1"
    for opt in ${OPTS[*]}; do
        if [ "$opt" == "--${flag}" ]; then
            return 0
        fi
    done
    return 1
}

function parse_argv() {
    # Parse command line arguments into positional arguments and
    # option flags. Store each in $ARGS, $OPTS.
    # Usage: parse_argv $*
    for item in $*; do
        if echo $item | grep -q -- '^--'; then
            OPTS+=($item)
        else
            ARGS+=($item)
        fi
    done
}

function db_var() {
    # Return an attribute of database config based on the symbolic
    # name
    # Usage: db_var SERVICE DATABASE -> $MYSQL_SERVICE_DATABASE
    local db="$1"
    local var="$2"

    eval echo "\$MYSQL_${db}_${var}"
}

function mysql_command() {
    # Run a mysql command with the usual connection information taken
    # from a symbolic configuration name
    # Usage: mysql_command SOURCE [command] [args..] -> stdout
    local whichdb="$1"
    shift
    local command=mysql
    if [ "$2" ]; then
        command=${1:-mysql}
        shift
    fi
    local db=$(db_var "${whichdb}" DATABASE)
    local host=$(db_var "${whichdb}" ADDRESS)
    local user=$(db_var "${whichdb}" USERNAME)
    local pass=$(db_var "${whichdb}" PASSWORD)

    if [ "$command" = "mysql" ]; then
        command="mysql --skip-column-names"
    fi

    $command -h"${host}" -u"${user}" -p"${pass}" "${db}" $* 2>"${LAST_MYSQL_ERR}"
}

function show_error() {
    # Prints the last error (if present) and removes the temporary
    # file
    if [ -f "${LAST_MYSQL_ERR}" ]; then
        cat "${LAST_MYSQL_ERR}"
        rm -f "${LAST_MYSQL_ERR}"
    fi
}

function check_env() {
    # Check that we have all the required environment variables set
    # Usage: sanity_check_env -> 0

    required="MYSQL_SOURCE_ADDRESS MYSQL_SOURCE_USERNAME MYSQL_SOURCE_PASSWORD MYSQL_SOURCE_DATABASE MYSQL_DESTINATION_ADDRESS MYSQL_DESTINATION_USERNAME MYSQL_DESTINATION_PASSWORD MYSQL_DESTINATION_DATABASE"
    for var in $required; do
        value=$(eval echo "\$$var")
        if [ -z "$value" ]; then
            echo "A value for $var was not provided but is required"
            return 1
        fi
    done
}

function check_db() {
    # Check a DB to see if it's missing, present, filled with data
    # Returns 0 if it is present with data, 1 if present but no data
    # or 2 if not present (or unable to connect)
    # Usage: check_db TARGET -> 0
    local whichdb="$1"
    local db=$(db_var "${whichdb}" DATABASE)

    local num_rows

    if ! echo "SELECT DATABASE()" | mysql_command "${whichdb}" >/dev/null 2>&1; then
        echo "Failed to connect to ${whichdb} database"
        show_error
        return 2
    fi

    num_rows=$(echo "SELECT sum(table_rows) FROM information_schema.tables WHERE table_schema = '${db}';" |
            mysql_command "${whichdb}")

    if [[ "${num_rows}" == "0" || "${num_rows}" == "NULL" ]]; then
        # No data found
        return 1
    else
        # Data found
        return 0
    fi
}

function migrate_data() {
    # Actually migrate data from a source to destination symbolic
    # database. Returns 1 if failure, 0 otherwise.
    # Usage: migrate_data SOURCE TARGET -> 0
    local source="$1"
    local destination="$2"
    local dump_flags="$3"
    local source_db=$(db_var "${source}" DATABASE)
    local tmpdir=$(mktemp --tmpdir="${TMPDIR}" -d migrate-db.XXXXXXXX)
    local tmpfile="${tmpdir}/from-${source_db}.sql"

    local source_host=$(db_var "${source}" ADDRESS)
    local destination_host=$(db_var "${destination}" ADDRESS)

    echo "Dumping from $source_host to $tmpfile"
    echo "mysqldump flags: $dump_flags"
    mysql_command $source mysqldump $dump_flags > $tmpfile || {
        echo 'Failed to dump source database:'
        show_error
        return 1
    }
    echo "Loading to $destination_host from $tmpfile"
    mysql_command $destination < $tmpfile || {
        echo 'Failed to load destination database:'
        show_error
        return 1
    }
    echo "Migration complete"
}

parse_argv $*

# Check that we have what we need or bail
check_env || exit $?
check_db SOURCE
source_present=$?
check_db DESTINATION
destination_present=$?

# Try to come up with a good reason to refuse to migrate
if [[ $source_present -eq 0  && $destination_present -eq 0 ]]; then
    echo "Migration has already completed. The destination database appears to have data."
    exit 3
elif [ $source_present -eq 1 ]; then
    echo "No data present in source database - nothing to migrate (new deployment?)"
    exit 4
elif [ $source_present -eq 2 ]; then
    echo "Unable to proceed without connection to source database"
    exit 5
elif [ $destination_present -eq 2 ]; then
    echo "Unable to proceed without connection to destination database"
    exit 5
fi

# If we get here, we expect to be able to migrate. Require them to opt into
# actual migration before we do anything.

echo Source database contains data, destination database does not. Okay to proceed with migration

if getflag migrate $*; then
    migrate_data SOURCE DESTINATION "${MYSQLDUMP_FLAGS}"
else
    echo "To actually migrate, run script with --migrate"
fi

rm -f $LAST_MYSQL_ERR
