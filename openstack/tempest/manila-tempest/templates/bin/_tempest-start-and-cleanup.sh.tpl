#!/usr/bin/env bash

set -o pipefail

{{- include "tempest-base.function_start_tempest_tests" . }}

{{- include "tempest-base.function_main" . }}

. /container.init/tempest-functions.sh

cleanup_tempest_leftovers
main
