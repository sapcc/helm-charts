#!/bin/sh
set -x
#set -euo pipefail

ALLOWED_DIFF=${WARMUP_ALLOWED_DIFF}

# The master redis will return the following lines
# 1) "master"
# 2) (integer) 3129659
# 3) 1) 1) "127.0.0.1"
#       2) "9001"
#       3) "3129242"
#    2) 1) "127.0.0.1"
#       2) "9002"
#       3) "3129543"
#
# Comparing the replication offsets of the slaves to check whether we have reached master state

determine_diff() {
  RESULT=$(redis-cli -h ${WARMUP_PEER} -p 22122 ROLE)
  COUNT=0
  SLAVE=0
  SLAVE_COUNT=0
  for LINE in ${RESULT}; do
    COUNT=$(( COUNT + 1 ))
    if [ ${SLAVE_COUNT} -gt 0 ]; then
      # Line Count within the correct Slave
      SLAVE_COUNT=$(( SLAVE_COUNT + 1 ))
    fi
    if [ ${COUNT} == 1 ] && [ ${LINE} != "master" ]; then
      echo ${ALLOWED_DIFF}
      return
    elif [ ${COUNT} == 2 ]; then
      MASTER=${LINE}
    elif [ $((${COUNT} % 3)) == 0 ]; then
      if [ ${LINE} == ${DYNO_INSTANCE} ]; then
        SLAVE_COUNT=1
      else
        SLAVE_COUNT=0
      fi
    elif [ ${SLAVE_COUNT} == 3 ]; then
      echo $(( MASTER - LINE ))
      return
    fi
  done
  echo ${ALLOWED_DIFF}
}

redis-cli -p 22122 ROLE
#TODO If this does not retirn OK, try another Peer
redis-cli -p 22122 REPLICAOF ${WARMUP_PEER} 22122
redis-cli -p 22122 ROLE

DIFF=${ALLOWED_DIFF}
until [ ${DIFF} -lt ${ALLOWED_DIFF} ]; do
  DIFF=$(determine_diff)
  sleep 0.5
done

redis-cli -p 22122 REPLICAOF NO ONE
redis-cli -p 22122 ROLE

# TODO Target warmup procedure
# /state/writes_only
# Stop redis sync
# /state/resuming // Set Dynomite to resuming state to allow writes and flush delayed writes"
# sleep 15        // sleep 15s for the flushing to catch up
# /state/normal
