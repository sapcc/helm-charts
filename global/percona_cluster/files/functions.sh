#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC2292,SC2250,SC2086,SC2312,SC2244,SC2027,SC2166

write_password_file() {
    if [[ -n "${MYSQL_ROOT_PASSWORD:+x}" ]]; then
        cat <<EOF > /root/.my.cnf
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
    fi
}

init_mysql() {
    DATADIR=/var/lib/mysql
    # if we have CLUSTER_JOIN - then we do not need to perform datadir initialize
    # the data will be copied from another node
    if [ ! -e "$DATADIR/mysql" ]; then
        if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" -a -z "$MYSQL_ROOT_PASSWORD_FILE" ]; then
            echo >&2 'error: database is uninitialized and password option is not specified '
            echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ROOT_PASSWORD_FILE,  MYSQL_ALLOW_EMPTY_PASSWORD or MYSQL_RANDOM_ROOT_PASSWORD'
            exit 1
        fi

        if [ ! -z "$MYSQL_ROOT_PASSWORD_FILE" -a -z "$MYSQL_ROOT_PASSWORD" ]; then
            MYSQL_ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)
        fi
        mkdir -p "$DATADIR"

        echo "Running --initialize-insecure on $DATADIR"
        ls -lah $DATADIR

        mysqld --user=mysql --datadir="$DATADIR" --initialize-insecure

        chown -R mysql:mysql "$DATADIR" || true # default is root:root 777
        if [ -f /var/log/mysqld.log ]; then
            chown mysql:mysql /var/log/mysqld.log
        fi
        echo 'Finished --initialize-insecure'

        mysqld --user=mysql --datadir="$DATADIR" --skip-networking &
        pid="$!"

        mysql=( mysql --protocol=socket -uroot )

        for i in {30..0}; do
            if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
                break
            fi
            echo 'MySQL init process in progress...'
            sleep 1
        done

        if [ "$i" = 0 ]; then
            echo >&2 'MySQL init process failed.'
            exit 1
        fi

        # sed is for https://bugs.mysql.com/bug.php?id=20545
        mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
        "${mysql[@]}" <<-EOSQL
            -- What's done in this file shouldn't be replicated
            --  or products like mysql-fabric won't work
            SET @@SESSION.SQL_LOG_BIN=0;

            CREATE USER 'root'@'${ALLOW_ROOT_FROM}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
            GRANT ALL ON *.* TO 'root'@'${ALLOW_ROOT_FROM}' WITH GRANT OPTION ;
            GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;

            CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY '${XTRABACKUP_PASSWORD}';
            GRANT RELOAD,PROCESS,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost' ;

            CREATE USER 'monitor'@'localhost' IDENTIFIED BY '${MONITOR_PASSWORD}' WITH MAX_USER_CONNECTIONS 10 ;
            GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'monitor'@'localhost' ;
            GRANT SELECT ON performance_schema.* TO 'monitor'@'localhost' ;

            CREATE USER 'mysql'@'localhost' IDENTIFIED BY '' ;

            DROP DATABASE IF EXISTS test ;
            FLUSH PRIVILEGES ;
EOSQL

        echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" | "${mysql[@]}"

        if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
            mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
        fi

        if [ "$MYSQL_DATABASE" ]; then
            echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
            mysql+=( "$MYSQL_DATABASE" )
        fi

        if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
            echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"

            if [ "$MYSQL_DATABASE" ]; then
                echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
            fi

            echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
        fi

        if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
            "${mysql[@]}" <<-EOSQL
            ALTER USER 'root'@'%' PASSWORD EXPIRE;
EOSQL
        fi
        if ! kill -s TERM "$pid" || ! wait "$pid"; then
            echo >&2 'MySQL init process failed.'
            exit 1
        fi

        echo
        echo 'MySQL init process done. Ready for start up.'
        echo
    fi
}

init_mysql_upgrade() {
    mysqld --version | tee /tmp/version_info
    DATADIR="/var/lib/mysql"

    if [ ! -f "${DATADIR}/version_info" ]; then
        echo '5.7.x' > "${DATADIR}/version_info"
    fi

    if [ -f "$DATADIR/version_info" ] && ! diff /tmp/version_info "${DATADIR}/version_info"; then
        mysqld --skip-networking --wsrep-provider='none' &
        pid="$!"

        mysql=( mysql --defaults-extra-file=/root/.my.cnf --protocol=socket -uroot -hlocalhost )

        for i in {120..0}; do
            if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
                break
            fi
            echo 'MySQL init process in progress...'
            sleep 1
        done
        if [ "$i" = 0 ]; then
            echo >&2 'MySQL init process failed.'
            exit 1
        fi

        mysql_upgrade "${mysql[@]:1}" --force
        if ! kill -s TERM "$pid" || ! wait "$pid"; then
            echo >&2 'MySQL init process failed.'
            exit 1
        fi
    fi
    mysqld --version > "${DATADIR}/version_info"
}

update_users() {
    mysql=( mysql --defaults-extra-file=/root/.my.cnf --protocol=socket -h localhost )
    for i in {120..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            break
        fi
        echo 'MySQL start process in progress...'
        sleep 1
    done

    "${mysql[@]}" <<-EOSQL
        CREATE USER IF NOT EXISTS 'xtrabackup'@'localhost' ;
        ALTER USER 'xtrabackup'@'localhost' IDENTIFIED BY '${XTRABACKUP_PASSWORD}' ;
        GRANT RELOAD,PROCESS,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost' ;

        CREATE USER IF NOT EXISTS 'monitor'@'localhost' ;
        ALTER USER 'monitor'@'localhost' IDENTIFIED BY '${MONITOR_PASSWORD}' WITH MAX_USER_CONNECTIONS 10 ;
        GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'monitor'@'localhost' ;
        GRANT SELECT ON performance_schema.* TO 'monitor'@'localhost' ;

        CREATE USER IF NOT EXISTS 'monitor'@'127.0.0.1' ;
        ALTER USER 'monitor'@'127.0.0.1' IDENTIFIED BY '${MONITOR_PASSWORD}' WITH MAX_USER_CONNECTIONS 10 ;
        GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, RELOAD ON *.* TO 'monitor'@'127.0.0.1' ;
        GRANT SELECT ON performance_schema.* TO 'monitor'@'127.0.0.1' ;

        FLUSH PRIVILEGES ;
EOSQL

    if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
        echo "CREATE USER IF NOT EXISTS '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"
        echo "ALTER USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}' ;" | "${mysql[@]}"

        if [ "$MYSQL_DATABASE" ]; then
            echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
        fi

        echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
    fi

}
