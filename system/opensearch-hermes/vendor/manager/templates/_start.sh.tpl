#!/bin/bash

base64 --decode /truststore/truststore.crypt > /opt/cerebro/truststore
/opt/cerebro/bin/cerebro -Dconfig.file=/manager-config/application.conf -Dlogback.configurationFile=/manager-config/logback.xml -Dlogger.file=/manager-config/logback.xml -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true -Des.networkaddress.cache.ttl=20 -Des.networkaddress.cache.negative.ttl=10 -Djavax.net.ssl.trustStore=/opt/cerebro/truststore -Djavax.net.ssl.trustStorePassword=${TRUSTSTORE_PASSWORD}

