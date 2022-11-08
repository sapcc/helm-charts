#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function bootstrapgalera {
  loginfo "${FUNCNAME[0]}" "init Galera cluster"
  exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --wsrep-new-cluster
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
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "mariadbd --wsrep-recover failed with '${MARIADBD_RESPONSE}'"
        exit 1
      fi
      IFS=':, ' SEQNO=($(echo ${MARIADBD_RESPONSE}))
      IFS="${oldIFS}"
      {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "wsrep-recover response: '${MARIADBD_RESPONSE}'" {{ end }}
      if [ ${SEQNO[-2]} -ge 0 ]; then
        loginfo "${FUNCNAME[0]}" "sequence number ${SEQNO[-2]} and historic UUID ${SEQNO[-3]} found"
        sed --in-place "s,^seqno:\s*-1,seqno:   ${SEQNO[-2]}," ${DATADIR}/grastate.dat
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "sequence number update failed"
          exit 1
        fi
        sed --in-place "s,^uuid:\s*00000000-0000-0000-0000-000000000000,uuid:   ${SEQNO[-3]}," ${DATADIR}/grastate.dat
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "uuid update failed"
          exit 1
        fi
        {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "grastate.dat file updated to '$(cat ${DATADIR}/grastate.dat)'" {{ else }} loginfo "${FUNCNAME[0]}" "grastate.dat file updated" {{ end }}

        setconfigmap "seqno" "${SEQNO[-2]}" "Update"
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
        logerror "${FUNCNAME[0]}" "The value '${SEQNO[-2]}' is not a valid sequence number"
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
  if [ -f ${DATADIR}/grastate.dat ] && [ -s ${DATADIR}/grastate.dat ]; then
      loginfo "${FUNCNAME[0]}" "init Galera cluster configuration already done"
      recovergalera
    else
      if [ ${HOSTNAME} == "{{ (include "nodeNamePrefix" (dict "global" $ "component" "application")) }}-0" ]; then
        bootstrapgalera
      else
        loginfo "${FUNCNAME[0]}" "will join the Galera cluster during the initial bootstrap triggered on the first node"
        startgalera
      fi
  fi
}

initgalera
