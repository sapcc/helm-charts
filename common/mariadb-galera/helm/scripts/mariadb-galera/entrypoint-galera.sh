#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function bootstrapgalera {
  loginfo "${FUNCNAME[0]}" "init Galera cluster"
  {{- /* disable Galera replication to be able to do PITR with mariadb-binlog https://jira.mariadb.org/browse/MDEV-29665 */}}
  if [ -f "${BASE}/etc/wipedata.flag" ]; then
    exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --wsrep-new-cluster --wsrep_on=OFF --expire-logs-days=0
  else
    exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --wsrep-new-cluster
  fi

}

function fetchseqnofromgrastate {
  IFS=": " SEQNO=($(grep 'seqno:' ${DATADIR}/grastate.dat))
  IFS="${oldIFS}"
  echo ${SEQNO[1]}
}

function recovergalera {
  loginfo "${FUNCNAME[0]}" "recover mariadbd galera if required"
  if [ ${PC_RECOVERY} == "true" ] && [ -f ${DATADIR}/gvwstate.dat ] && [ -s ${DATADIR}/gvwstate.dat ]; then
    {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "gvwstate.dat content: '$(cat ${DATADIR}/gvwstate.dat)'" {{ end }}
    loginfo "${FUNCNAME[0]}" "primary component recovery possible"
    startgalera
  else
    IFS=": " SAFE_TO_BOOTSTRAP=($(grep 'safe_to_bootstrap:' ${DATADIR}/grastate.dat))
    IFS="${oldIFS}"
    SEQNO=$(fetchseqnofromgrastate)

    if [ ${SAFE_TO_BOOTSTRAP[1]} -eq 1 ] && [ ${SEQNO} -ne -1 ]; then
      loginfo "${FUNCNAME[0]}" 'positive sequence number found'
      setconfigmap "seqno" "${SEQNO}" "Update"
      selectbootstrapnode
      if [ "${NODENAME[0]}" == "${POD_NAME}" ]; then
        bootstrapgalera
      else
        startgalera
      fi
    else
      loginfo "${FUNCNAME[0]}" "start 'mariadbd --wsrep-recover' to find last sequence number"
      MARIADBD_RESPONSE=$(mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error --wsrep-recover 2>&1)
      # '2023-06-29 15:33:06 0 [Note] WSREP: Recovered position: d1211d51-168e-11ee-bb72-d392a3952878:70,0-10-62'
      # grep will match: 70
      SEQNO=$(echo ${MARIADBD_RESPONSE} | grep --only-matching --perl-regexp --regexp='\[Note\] WSREP: Recovered position: .+:\K([0-9]+)')
      # '2023-06-29 15:33:06 0 [Note] WSREP: Recovered position: d1211d51-168e-11ee-bb72-d392a3952878:70,0-10-62'
      # grep will match: d1211d51-168e-11ee-bb72-d392a3952878
      UUID=$(echo ${MARIADBD_RESPONSE} | grep --only-matching --perl-regexp --regexp='\[Note\] WSREP: Recovered position: \K([0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12})')
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "mariadbd --wsrep-recover failed with '${MARIADBD_RESPONSE}'"
        exit 1
      fi
      {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "wsrep-recover response: '${MARIADBD_RESPONSE}'" {{ end }}
      if [ ${SEQNO} -ge 0 ]; then
        loginfo "${FUNCNAME[0]}" "sequence number ${SEQNO} and historic UUID ${UUID} found"
        sed --in-place "s,^seqno:\s*-1,seqno:   ${SEQNO}," ${DATADIR}/grastate.dat
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "sequence number update failed"
          exit 1
        fi
        sed --in-place "s,^uuid:\s*00000000-0000-0000-0000-000000000000,uuid:   ${UUID}," ${DATADIR}/grastate.dat
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "uuid update failed"
          exit 1
        fi
        {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "grastate.dat file updated to '$(cat ${DATADIR}/grastate.dat)'" {{ else }} loginfo "${FUNCNAME[0]}" "grastate.dat file updated" {{ end }}

        setconfigmap "seqno" "${SEQNO}" "Update"
        selectbootstrapnode
        if [ "${NODENAME[0]}" == "${POD_NAME}" ]; then
          sed --in-place "s,^safe_to_bootstrap:\s*0,safe_to_bootstrap: 1," ${DATADIR}/grastate.dat
          if [ $? -ne 0 ]; then
            logerror "${FUNCNAME[0]}" "safe_to_bootstrap update failed"
            exit 1
          fi
          bootstrapgalera
        else
          startgalera
        fi
      else
        logerror "${FUNCNAME[0]}" "The value '${SEQNO}' is not a valid sequence number"
        exit 1
      fi
    fi
  fi
}

function startgalera {
  loginfo "${FUNCNAME[0]}" "starting mariadbd galera process"
  exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error
}

function initgalera {
  if [ -f "${BASE}/etc/wipedata.flag" ]; then
    if [ ${HOSTNAME} == "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-0" ]; then
      bootstrapgalera
    else
      loginfo "${FUNCNAME[0]}" "start sleep mode because wipedata flag has been set"
      sleep 86400
    fi
  else
    if [ -f ${DATADIR}/grastate.dat ] && [ -s ${DATADIR}/grastate.dat ]; then
        loginfo "${FUNCNAME[0]}" "init Galera cluster configuration already done"
        recovergalera
      else
        if [ ${HOSTNAME} == "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-0" ]; then
          bootstrapgalera
        else
          loginfo "${FUNCNAME[0]}" "will join the Galera cluster during the initial bootstrap triggered on the first node"
          startgalera
        fi
    fi
  fi
}

initgalera
