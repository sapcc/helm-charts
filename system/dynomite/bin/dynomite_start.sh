#!/bin/sh
set -eo pipefail

attempt=1
wait=1

if [ -n "${WARMUP_PEER}" ]; then
  until redis-cli -p 22122 ping; do
    if [ $attempt -gt 30 ]; then
      echo "Too many failed attempts. Exiting..."
      exit 1
    fi
    attempt=$(( attempt + 1 ))
    sleep $wait
  done

  /dynomite-bin/warmup.sh
fi

/usr/bin/dynomite "$@"
