#!/bin/bash

/influx-cli-wrapper.sh show series | grep -v ^name: | grep -v ^--- | grep -v ^_key | grep -v alarm_state_history | awk '{print $1}' | awk -F, '{print $1}' | sort -u
