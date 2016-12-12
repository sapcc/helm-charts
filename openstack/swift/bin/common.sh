#/bin/bash

function start_application {
    if [ "$DEBUG_CONTAINER" = "true" ]
    then
        tail -f /dev/null
    else
        _start_application
    fi
}
