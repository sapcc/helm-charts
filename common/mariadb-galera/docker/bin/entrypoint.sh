
#!/usr/bin/env bash
BASE=/opt/${SOFTWARE_NAME}

declare -f initdb startdb echoStdOut echoStdErr

function echoStdOut {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.level\":\"info\",\"message\":\"%s\"}\n" "$(date +%Y.%m.%d-%H:%M:%S-%Z)" "$*" >>/dev/stdout
}

function echoStdErr {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.level\":\"error\",\"message\":\"%s\"}\n" "$(date +%Y.%m.%d-%H:%M:%S-%Z)" "$*" >>/dev/stderr
}

function initdb {
  # check if the data folder already contains database structures
  echoStdOut "init databases if required"
  if [ -d "${BASE}/data/mysql" ]; then
    echoStdOut "Database structures already exist."
    return
  else
    /usr/bin/mariadb-install-db --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-test-db
    if [ $? -ne 0 ]; then
      echoStdErr "Database initialization has been failed"
      exit 1
    fi
  fi
  echoStdOut "init databases done"
}

function startdb {
  # check if the data folder already contains database structures
  echoStdOut "starting mariadbd process"
  /usr/sbin/mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error
  if [ $? -ne 0 ]; then
    echoStdErr "mariadbd startup failed"
    exit 1
  fi
}

initdb
startdb
