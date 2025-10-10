#!/usr/bin/env bash
set -ex

designate-manage --config-file /etc/designate/designate.conf --config-file /etc/designate/secrets.conf database sync

{{ include "utils.script.job_finished_hook" . }}
