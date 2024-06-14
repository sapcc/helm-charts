oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${MARIADB_DATADIR-/opt/mariadb/data}
LOGDIR=${MARIADB_LOGDIR-/opt/mariadb/log}
export CONTAINER_IP=$(hostname --ip-address)
export POD_NAME=$(hostname --short)
IFS=". " softVerProps=($(echo ${SOFTWARE_VERSION}))
IFS="${oldIFS}"
softMinorVer="${softVerProps[0]}.${softVerProps[1]}"
IFS="+ " softVerProps=($(echo ${softVerProps[2]}))
IFS="${oldIFS}"
export SOFTWARE_VERSION_CLEAN="${softMinorVer}.${softVerProps[0]}"

if [ -f "${BASE}/bin/common-functions-extended.sh" ]; then
  source ${BASE}/bin/common-functions-extended.sh
fi

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y-%m-%dT%H:%M:%S+%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logdebug {
  logjson "stdout" "debug" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

function templateconfig {
  local int

  loginfo "${FUNCNAME[0]}" "template MariaDB configurations if required"
  if [ -f ${BASE}/etc/conf.d/tpl/my.cnf.${POD_NAME}.tpl ]; then
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      cat ${BASE}/etc/conf.d/tpl/my.cnf.${POD_NAME}.tpl | envsubst > ${BASE}/etc/conf.d/my.cnf
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "${BASE}/etc/conf.d/tpl/my.cnf.${POD_NAME}.tpl rendering has been failed (${int} retries left)"
        sleep ${WAIT_SECONDS}
      else
        break
      fi
    done
    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "template MariaDB configurations has been finally failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "template MariaDB configurations done"
  else
    loginfo "${FUNCNAME[0]}" "templating skipped because of missing ${BASE}/etc/conf.d/tpl/my.cnf.${POD_NAME}.tpl file"
  fi
}

# readroleprivileges 'mysql_exporter' '/opt/mariadb/etc/sql/'
function readroleprivileges {
  if [ -f "${2}${1}.role.yaml" ]; then
    export DB_ROLE_PRIVS=$(yq '.privileges | join(", ")' ${2}${1}.role.yaml)
  else
    loginfo "${FUNCNAME[0]}" "role setup skipped because of missing ${2}${1} file"
    return 1
  fi
}

# readroleobject 'mysql_exporter' '/opt/mariadb/etc/sql/'
function readroleobject {
  if [ -f "${2}${1}.role.yaml" ]; then
    export DB_ROLE_OBJ=$(yq '.object' ${2}${1}.role.yaml)
  else
    loginfo "${FUNCNAME[0]}" "role setup skipped because of missing ${2}${1} file"
    return 1
  fi
}

# readrolegrant 'mysql_exporter' '/opt/mariadb/etc/sql/'
function readrolegrant {
  if [ -f "${2}${1}.role.yaml" ]; then
    if [ "$(yq '.grant' ${2}${1}.role.yaml)" == true ]; then
      export DB_ROLE_GRANT="WITH GRANT OPTION"
    else
      export DB_ROLE_GRANT=""
    fi
  else
    loginfo "${FUNCNAME[0]}" "role setup skipped because of missing ${2}${1} file"
    return 1
  fi
}

# setup database role definition
# role name as variable for the function
# readroleprivileges, readroleobject, readrolegrant have to be triggered before to populate the related variables
# setuprole 'mysql_exporter' "${DB_ROLE_PRIVS}" "${DB_ROLE_OBJ}" "${DB_ROLE_GRANT}"
function setuprole {
  local tplfile=setuprole.sql.tpl
  if [ -f "${BASE}/etc/sql/${tplfile}" ]; then
    local int
    export DB_ROLE=${1}
    export DB_ROLE_PRIVS=${2}
    export DB_ROLE_OBJ=${3}
    export DB_ROLE_GRANT=${4}

    loginfo "${FUNCNAME[0]}" "setup ${DB_ROLE} role"
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
        cat ${BASE}/etc/sql/${tplfile} | envsubst | $(${MYSQL_SVC_CONNECT})
      else
        cat ${BASE}/etc/sql/${tplfile} | envsubst | mysql --protocol=socket --user=root --batch
      fi
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "'${DB_ROLE}' role setup has been failed(${int} retries left)"
        sleep ${WAIT_SECONDS}
      else
        loginfo "${FUNCNAME[0]}" "'${DB_ROLE}' role setup done"
        break
      fi
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "role setup has been finally failed"
      exit 1
    fi
    export -n DB_ROLE
    export -n DB_ROLE_PRIVS
    export -n DB_ROLE_OBJ
    export -n DB_ROLE_GRANT
  else
    loginfo "${FUNCNAME[0]}" "role setup skipped because of missing ${BASE}/etc/sql/${tplfile} file"
  fi
}

# grantrole rolename username hostname admingrant(or empty)
# grantrole 'mysql_exporter' "${MARIADB_MONITORING_USERNAME}" '%' 'WITH ADMIN OPTION'
function grantrole {
  local tplfile=grantrole.sql.tpl
  if [ -f "${BASE}/etc/sql/${tplfile}" ]; then
    local int
    export DB_ROLE=${1}
    export DB_USERNAME=${2}
    export DB_HOST=${3}
    export DB_ADMIN_GRANT=${4}

    loginfo "${FUNCNAME[0]}" "grant ${DB_ROLE} role to '${DB_USERNAME}@${DB_HOST}'"
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
        cat ${BASE}/etc/sql/${tplfile} | envsubst | $(${MYSQL_SVC_CONNECT})
      else
        cat ${BASE}/etc/sql/${tplfile} | envsubst | mysql --protocol=socket --user=root --batch
      fi
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "'${DB_ROLE}' role grant has been failed(${int} retries left)"
        sleep ${WAIT_SECONDS}
      else
        loginfo "${FUNCNAME[0]}" "'${DB_ROLE}' role grant done"
        break
      fi
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "role setup has been finally failed"
      exit 1
    fi
    export -n DB_HOST
    export -n DB_USERNAME
    export -n DB_ROLE
    export -n DB_ADMIN_GRANT
  else
    loginfo "${FUNCNAME[0]}" "role grant skipped because of missing ${BASE}/etc/sql/${tplfile} file"
  fi
}

# setdefaultrole rolename username hostname
# setdefaultrole 'mysql_exporter' "${MARIADB_MONITORING_USERNAME}" '%'
function setdefaultrole {
  local tplfile=setdefaultrole.sql.tpl
  if [ -f "${BASE}/etc/sql/${tplfile}" ]; then
    local int
    export DB_ROLE=${1}
    export DB_USERNAME=${2}
    export DB_HOST=${3}

    loginfo "${FUNCNAME[0]}" "set ${DB_ROLE} as default role to '${DB_USERNAME}@${DB_HOST}'"
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
        cat ${BASE}/etc/sql/${tplfile} | envsubst | $(${MYSQL_SVC_CONNECT})
      else
        cat ${BASE}/etc/sql/${tplfile} | envsubst | mysql --protocol=socket --user=root --batch
      fi
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "'${DB_ROLE}' default role config has been failed(${int} retries left)"
        sleep ${WAIT_SECONDS}
      else
        loginfo "${FUNCNAME[0]}" "'${DB_ROLE}' default role config done"
        break
      fi
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "default role config has been finally failed"
      exit 1
    fi
    export -n DB_HOST
    export -n DB_USERNAME
    export -n DB_ROLE
  else
    loginfo "${FUNCNAME[0]}" "default role config skipped because of missing ${BASE}/etc/sql/${tplfile} file"
  fi
}

# setup username password rolename connectionlimit hostname authplugin admingrant(or empty)
# setupuser "${MARIADB_MONITORING_USERNAME}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '%' 'mysql_native_password' 'WITH ADMIN OPTION'
function setupuser {
  local tplfile=setupuser.sql.tpl
  if [ -f "${BASE}/etc/sql/${tplfile}" ] && [ -n "${1}" ] && [ -n "${2}" ]; then
    local int
    export DB_USERNAME=${1}
    export DB_PASS=${2}
    export DB_ROLE=${3}
    export CONN_LIMIT=${4}
    export DB_HOST=${5}
    export DB_AUTHPLUGIN=${6}
    export DB_ADMIN_GRANT=${7}

    loginfo "${FUNCNAME[0]}" "setup '${DB_USERNAME}@${DB_HOST}' privileges"
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
        cat ${BASE}/etc/sql/${tplfile} | envsubst | $(${MYSQL_SVC_CONNECT})
      else
        cat ${BASE}/etc/sql/${tplfile} | envsubst | mysql --protocol=socket --user=root --batch
      fi
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "'${DB_USERNAME}@${DB_HOST}' user setup has been failed(${int} retries left)"
        sleep ${WAIT_SECONDS}
      else
        if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
          ${MYSQL_SVC_CONNECT} --execute="FLUSH PRIVILEGES;" --batch --skip-column-names
        else
          mysql --protocol=socket --user=root --execute="FLUSH PRIVILEGES;" --batch --skip-column-names
        fi
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "flush privileges failed(${int} retries left)"
          sleep ${WAIT_SECONDS}
        else
          loginfo "${FUNCNAME[0]}" "'${DB_USERNAME}@${DB_HOST}' user setup done"
          break
        fi
      fi
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "user setup has been finally failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "user setup done"
    export -n DB_USERNAME
    export -n DB_PASS
    export -n DB_ROLE
    export -n DB_HOST
    export -n CONN_LIMIT
    export -n DB_AUTHPLUGIN
    export -n DB_ADMIN_GRANT
  else
    loginfo "${FUNCNAME[0]}" "user setup skipped because of missing ${BASE}/etc/sql/${tplfile} file and/or missing MARIADB_XYZ_USERNAME and/or MARIADB_XYZ_PASSWORD env vars"
  fi
}

function listdbandusers {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "list databases and users(${int} retries left)"
    if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
      ${MYSQL_SVC_CONNECT} --execute="SHOW DATABASES; SELECT user,is_role,host,Grant_priv,Super_priv,default_role,plugin FROM mysql.user ORDER BY user;" --table
    else
      mysql --protocol=socket --user=root --batch --execute="SHOW DATABASES; SELECT user,is_role,host,Grant_priv,Super_priv,default_role,plugin FROM mysql.user ORDER BY user;" --table
    fi
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "list databases and users has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "list databases and users has been finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "list databases and users done"
}
