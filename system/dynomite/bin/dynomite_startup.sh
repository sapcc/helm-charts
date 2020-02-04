#!/bin/sh
set -eo pipefail

if [ -n "${WARMUP_PEER}" ]; then
  if [ -n "${WARMUP_ALLOWED_DIFF}" ]; then
    ALLOWED_DIFF="--accepted-diff=${WARMUP_ALLOWED_DIFF}"
  fi
  /usr/bin/powder-monkey backend --backend-password=${REQUIREPASS} warmup ${ALLOWED_DIFF} --replica-announce-ip=${DYNO_INSTANCE} ${WARMUP_PEER}
fi

if [ -n "${DEBUG}" ]; then
  VERBOSE_LEVEL="-v11"
fi

exec /usr/bin/dynomite --conf-file=/config/dynomite.yaml ${VERBOSE_LEVEL}
