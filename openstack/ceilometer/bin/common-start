#!/bin/bash

# on Ubuntu, python does not recognize the system certificate bundle
export OS_CACERT=/etc/ssl/certs/ca-certificates.crt
# this is required for the python request package
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# unset all proxy settings
unset http_proxy https_proxy no_proxy
