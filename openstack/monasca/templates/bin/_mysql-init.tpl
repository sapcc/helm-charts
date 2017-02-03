#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {
  # flag to mark successful preparation of schema and users (in persistent area)
  export MONASCA_MYSQL_PREP_FILE="/var/lib/mysql/cfg-mysql.tstamp"
  export EXT_CONFIG_FILE="/monasca-etc/mysql-mysql.cnf"
}

function start_application {
  # preparation of MySQL users and schema
  if [ ! -e ${MONASCA_MYSQL_PREP_FILE} ]; then
    echo "------------------------------------------------------------------------------"
    echo "Fresh MySQL installation detected (no data). Preparing for use with Monasca"
    echo "------------------------------------------------------------------------------"

    # to be safe, better correct the permissions of the emptydir volume
    chown mysql:mysql /var/lib/mysql
    chmod 755 /var/lib/mysql
    # copy over our saved initial mysql files to the freshly mounted volume in kubernetes
    cp -af /var/lib/mysql.cp/* /var/lib/mysql
    # initialize database
    chpst -L /var/lib/mysql/container.lock mysqld_safe --defaults-extra-file=${EXT_CONFIG_FILE} &
    sleep 10
    mysql --user=root < /monasca-etc/mysql-mon-schema.sql
    echo "-------------------------------------------------------------"
    echo "Shutting down MySQL to restart with new schema and users"
    echo "-------------------------------------------------------------"
    # shutdown mysql
    sleep 10

    echo "Monasca environment successfully prepared"
    # set flag persistently
    date --utc > ${MONASCA_MYSQL_PREP_FILE}
    # exit to restart
    exit 0
  else
    # in case mysql has not been installed fresh we need to correct the permissions of the emptydir volume
    chown mysql:mysql /var/lib/mysql
    chmod 755 /var/lib/mysql
  fi
  
  # start fluentd log streaming (since MariaDB cannot log to stdout)
}

function diagnose_application {
  set +e

  echo "mysql.log ----------------------------------------------------------------------------------------------------"
  cat /var/log/mysql/mysql.log
  echo "mysql-slow.log ----------------------------------------------------------------------------------------------------"
  cat /var/log/mysql/mysql-slow.log
  echo "error.log ----------------------------------------------------------------------------------------------------"
  cat /var/log/mysql/error.log
  exit 0
}

set -e

process_config

start_application

diagnose_application
