#!/bin/bash

cp /fluent-bin/fluent.conf /etc/fluent/fluent.conf
/usr/local/bin/fluentd --use-v1-config
