function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y-%m-%dT%H:%M:%S+%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logdebug {
  logjson "stdout" "debug" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

function logstderr {
  echo "${1}" >&2
}

function checkrabbitmq {
  if [[ -z "${1}" ]]; then
    logstderr 'missing check name'
    exit 1
  else
    case "$1" in
      server_version)
        if ! rabbitmq-diagnostics --node rabbit@$(hostname --short) --timeout {{ $.Values.livenessProbe.timeoutSeconds | int }} --quiet ${1} | grep --quiet "${RABBITMQ_VERSION}"; then
          logstderr "RabbitMQ ${1} check failed"
          exit 1
        fi
        ;;
      *)
        if ! rabbitmq-diagnostics --node rabbit@$(hostname --short) --timeout {{ $.Values.livenessProbe.timeoutSeconds | int }} --quiet ${1}; then
          logstderr "RabbitMQ ${1} check failed"
          exit 1
        fi
        ;;
    esac
  fi
}
