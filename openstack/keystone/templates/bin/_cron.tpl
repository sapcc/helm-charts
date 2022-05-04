#!/usr/bin/env bash

export STDOUT=${STDOUT:-/proc/1/fd/1}
export STDERR=${STDERR:-/proc/1/fd/2}

# note: currently there are no cron jobs, but they might appear in future, so keep the file

exec cron -f
