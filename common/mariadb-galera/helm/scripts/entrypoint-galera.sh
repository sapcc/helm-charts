#!/usr/bin/env bash
set +e
set -u
set -o pipefail

BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
MAX_RETRIES=10
WAIT_SECONDS=6
declare -a NODENAME=()

source ${BASE}/bin/common-functions.sh

function templateconfig {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "template MariaDB configurations (${int} retries left)"
    cat ${BASE}/etc/conf.d/tpl/my.cnf.${CONTAINER_NAME}.tpl | envsubst > ${BASE}/etc/conf.d/my.cnf
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "${BASE}/etc/conf.d/tpl/my.cnf.${CONTAINER_NAME}.tpl rendering has been failed"
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
}

function bootstrapgalera {
  loginfo "${FUNCNAME[0]}" "init Galera cluster"
  exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --wsrep-new-cluster
}

function recovergalera {
  loginfo "${FUNCNAME[0]}" "recover mariadbd galera if required"
  if [ ${PC_RECOVERY} == "true" ] && [ -f ${DATADIR}/gvwstate.dat ] && [ -s ${DATADIR}/gvwstate.dat ]; then
    {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "gvwstate.dat content: '$(cat ${DATADIR}/gvwstate.dat)'" {{ end }}
    loginfo "${FUNCNAME[0]}" "primary component recovery possible"
    startgalera
  else
    IFS=": " SAFE_TO_BOOTSTRAP=($(grep 'safe_to_bootstrap:' ${DATADIR}/grastate.dat))
    IFS=": " SEQNO=($(grep 'seqno:' ${DATADIR}/grastate.dat))
    IFS="${oldIFS}"
    if [ ${SAFE_TO_BOOTSTRAP[1]} -eq 1 ] && [ ${SEQNO[1]} -ne -1 ]; then
      loginfo "${FUNCNAME[0]}" 'positive sequence number found'
      setconfigmap "seqno" "${SEQNO[1]}" "Update"
      selectbootstrapnode
      if [ "${NODENAME[0]}" == "${CONTAINER_NAME}" ]; then
        bootstrapgalera
      else
        startgalera
      fi
    else
      loginfo "${FUNCNAME[0]}" "start 'mariadbd --wsrep-recover' to find last sequence number"
      MARIADBD_RESPONSE=$(mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error --wsrep-recover 2>&1)
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "mariadbd --wsrep-recover failed with '${MARIADBD_RESPONSE}'"
        exit 1
      fi
      IFS=': ' SEQNO=($(echo ${MARIADBD_RESPONSE}))
      IFS="${oldIFS}"
      {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "wsrep-recover response: '${MARIADBD_RESPONSE}'" {{ end }}
      if [ ${SEQNO[-1]} -ge 0 ]; then
        loginfo "${FUNCNAME[0]}" "sequence number ${SEQNO[-1]} found"
        sed -i "s,^seqno:\s*-1,seqno:   ${SEQNO[-1]}," ${DATADIR}/grastate.dat
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "sequence number update failed"
          exit 1
        fi
        {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "grastate.dat file updated to '$(cat ${DATADIR}/grastate.dat)'" {{ else }} loginfo "${FUNCNAME[0]}" "grastate.dat file updated" {{ end }}

        setconfigmap "seqno" "${SEQNO[-1]}" "Update"
        selectbootstrapnode
        if [ "${NODENAME[0]}" == "${CONTAINER_NAME}" ]; then
          sed -i "s,^safe_to_bootstrap:\s*0,safe_to_bootstrap: 1," ${DATADIR}/grastate.dat
          if [ $? -ne 0 ]; then
            logerror "${FUNCNAME[0]}" "safe_to_bootstrap update failed"
            exit 1
          fi
          bootstrapgalera
        else
          startgalera
        fi
      else
        logerror "${FUNCNAME[0]}" "The value '${SEQNO[-1]}' is not a valid sequence number"
        exit 1
      fi
    fi
  fi
}

function selectbootstrapnode {
  local int
  local SEQNO_FILES="${BASE}/etc/galerastatus/{{ $.Release.Name }}-*.seqno"

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "Find Galera node with highest sequence number (${int} retries left)"
    SEQNO_FILE_COUNT=$(grep -c '{{ $.Release.Name }}-*' ${SEQNO_FILES} | grep -c -e "${BASE}/etc/galerastatus/{{ $.Release.Name }}-.*.seqno:1")
    if [ ${SEQNO_FILE_COUNT} -eq {{ ($.Values.replicas|int) }} ]; then
      IFS=": " NODENAME=($(grep --no-filename '{{ $.Release.Name }}-*' ${SEQNO_FILES} | sort --key=2 --reverse --numeric-sort --field-separator=: | head -1))
      IFS="${oldIFS}"
      if [[ "${NODENAME[0]}" =~ ^{{ $.Release.Name }}-.* ]]; then
        loginfo "${FUNCNAME[0]}" "Galera nodename '${NODENAME[0]}' with the sequence number '${NODENAME[1]}' selected"
        break
      else
        logerror "${FUNCNAME[0]}" "nodename '${NODENAME[0]}' not valid"
        exit 1
      fi
    else
      loginfo "${FUNCNAME[0]}" "only ${SEQNO_FILE_COUNT} of {{ ($.Values.replicas|int) }} sequence numbers found. Will wait $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) )) seconds"
      sleep  $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "Sequence number search finally incomplete(${SEQNO_FILE_COUNT}/{{ ($.Values.replicas|int)}})"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "Sequence number search done"
}

function startgalera {
  loginfo "${FUNCNAME[0]}" "starting mariadbd galera process"
  exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error
}

function initgalera {
  if [ -f ${DATADIR}/grastate.dat ] && [ -s ${DATADIR}/grastate.dat ]; then
      loginfo "${FUNCNAME[0]}" "init Galera cluster configuration already done"
      recovergalera
    else
      if [ ${HOSTNAME} == "{{ $.Release.Name }}-0" ]; then
        bootstrapgalera
      else
        loginfo "${FUNCNAME[0]}" "will join the Galera cluster during the initial bootstrap triggered on the first node"
        startgalera
      fi
  fi
}

templateconfig
initgalera
