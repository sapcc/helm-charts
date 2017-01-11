#!/bin/bash

. /container.init/common-start 

echo "Start storm UI"
/opt/storm/current/bin/storm ui
