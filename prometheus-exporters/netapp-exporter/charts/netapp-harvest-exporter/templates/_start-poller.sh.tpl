#!/bin/sh
until [ $(find /opt/harvest/shared -name '*.yaml' | wc -l) -gt 0 ]; do
    echo "Waiting for config file to be generated"
    sleep 5
done

# Find the config file in ./shared and run poller in it.
#
# The config file is generated in ./shared by netappsd-worker, and the file name is the same as the poller name.
exec find /opt/harvest/shared -name '*.yaml' -exec sh -c 'foo=$1; /opt/harvest/bin/poller --config $foo -p $(basename $foo .yaml)' _ {} \;