#!/bin/bash

CONCOURSE_TARGET="${CONCOURSE_TARGET:-main}"
FLY_BIN="${FLY_BIN:-fly-7.6.0}"

for file in teams/*.yaml; do
    TEAM=`echo ${file} | cut -d '/' -f2 | cut -d'.' -f1`
    echo "Setting roles for team ${TEAM} ..."
    ${FLY_BIN} set-team -t ${CONCOURSE_TARGET} -n ${TEAM} -c $file --non-interactive
done
