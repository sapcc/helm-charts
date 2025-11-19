#!/bin/bash
set -ex

lunaclient ()
    {
    mv /usr/safenet /thales
    NOW="$(date +%Y%m%d)"
    cd /thales/safenet/lunaclient/libs/64/
    rm -f libCryptoki2_64.so
    ln -s libCryptoki2.so libCryptoki2_64.so
    /thales/safenet/lunaclient/bin/64/configurator setValue -s Chrystoki2 -e LibUNIX -v /thales/safenet/lunaclient/libs/64/libCryptoki2.so
    /thales/safenet/lunaclient/bin/64/configurator setValue -s Chrystoki2 -e LibUNIX64 -v /thales/safenet/lunaclient/libs/64/libCryptoki2_64.so
    /thales/safenet/lunaclient/bin/64/configurator setValue -s Misc -e ToolsDir -v /thales/safenet/lunaclient/bin/64/
    /thales/safenet/lunaclient/bin/64/configurator setValue -s Misc -e MutexFolder -v /thales/safenet/lunaclient/lock
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "LunaSA Client" -e SSLConfigFile -v /thales/safenet/lunaclient/openssl.cnf
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "LunaSA Client" -e ServerCAFile -v /thales/safenet/lunaclient/config/certs/CAFile.pem
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "LunaSA Client" -e "ClientCertFile" -v /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "LunaSA Client" -e "ClientPrivKeyFile" -v /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "Secure Trusted Channel" -e ClientTokenLib -v /thales/safenet/lunaclient/libs/64/libSoftToken.so
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "Secure Trusted Channel" -e SoftTokenDir -v /thales/safenet/lunaclient/config/stc/token
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "Secure Trusted Channel" -e ClientIdentitiesDir -v /thales/safenet/lunaclient/config/stc/client_identities
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "Secure Trusted Channel" -e PartitionIdentitiesDir -v /thales/safenet/lunaclient/config/stc/partition_identities

    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Label -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Label | include "resolve_secret" }}
    {{- if .Values.hsm.ha.enabled }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00SN -v 1{{ .Values.lunaclient.VirtualToken.VirtualToken00SN | include "resolve_secret" }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Members -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Members | include "resolve_secret" }},{{ .Values.lunaclient.VirtualToken.VirtualToken00Members02 | include "resolve_secret" }}
    {{- else}}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00SN -v {{ .Values.lunaclient.VirtualToken.VirtualToken00SN | include "resolve_secret" }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Members -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Members | include "resolve_secret" }}
    {{- end}}

    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualTokenActiveRecovery -v {{ .Values.lunaclient.VirtualToken.VirtualTokenActiveRecovery | include "resolve_secret" }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HASynchronize" -e {{ .Values.lunaclient.VirtualToken.VirtualToken00Label | include "resolve_secret" }} -v {{ .Values.lunaclient.HASynchronize.sync }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e haLogStatus -v {{ .Values.lunaclient.HAConfiguration.haLogStatus | include "resolve_secret" }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e reconnAtt -v {{ .Values.lunaclient.HAConfiguration.reconnAtt }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e HAOnly -v {{ .Values.lunaclient.HAConfiguration.HAOnly }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e haLogPath -v {{ .Values.lunaclient.HAConfiguration.haLogPath | include "resolve_secret" }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e logLen -v {{ .Values.lunaclient.HAConfiguration.logLen }}
    /thales/safenet/lunaclient/bin/64/vtl createCert -n $HOSTNAME-$NOW

    #REGISTER HSM1
    echo "Registering HSM01"
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} /thales/safenet/lunaclient/config/certs/$HOSTNAME-$NOW.pem {{ .Values.lunaclient.conn.user | include "resolve_secret" }}@{{ .Values.lunaclient.conn.ip | include "resolve_secret" }}:.
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} {{ .Values.lunaclient.conn.user | include "resolve_secret" }}@{{ .Values.lunaclient.conn.ip | include "resolve_secret" }}:server.pem /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/vtl addserver -n {{ .Values.lunaclient.conn.ip | include "resolve_secret" }} -c  /thales/safenet/lunaclient/config/certs/server.pem
    echo "client register -c $HOSTNAME-$NOW" -h $HOSTNAME-$NOW > /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    echo "client assignPartition -c $HOSTNAME-$NOW -p {{ .Values.lunaclient.conn.par | include "resolve_secret"  }}" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    echo "exit" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    /thales/safenet/lunaclient/bin/64/plink {{ .Values.lunaclient.conn.ip | include "resolve_secret" }} -ssh -l {{ .Values.lunaclient.conn.user | include "resolve_secret" }} -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} -v < /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    
    {{- if .Values.hsm.ha.enabled }}
    #REGISTER HSM2
    echo "Registering HSM02"
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} /thales/safenet/lunaclient/config/certs/$HOSTNAME-$NOW.pem {{ .Values.lunaclient.conn.user | include "resolve_secret" }}@{{ .Values.lunaclient.conn.ip02 | include "resolve_secret" }}:.
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} {{ .Values.lunaclient.conn.user | include "resolve_secret" }}@{{ .Values.lunaclient.conn.ip02 | include "resolve_secret" }}:server.pem /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/vtl addserver -n {{ .Values.lunaclient.conn.ip02 | include "resolve_secret" }} -c  /thales/safenet/lunaclient/config/certs/server.pem
    echo "client register -c $HOSTNAME-$NOW" -h $HOSTNAME-$NOW > /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    echo "client assignPartition -c $HOSTNAME-$NOW -p {{ .Values.lunaclient.conn.par02 | include "resolve_secret" }}" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    echo "exit" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    /thales/safenet/lunaclient/bin/64/plink {{ .Values.lunaclient.conn.ip02 | include "resolve_secret" }} -ssh -l {{ .Values.lunaclient.conn.user | include "resolve_secret" }} -pw {{ .Values.lunaclient.conn.pwd | include "resolve_secret" }} -v < /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    {{- end}}

    cp /thales/safenet/lunaclient/config/Chrystoki.conf /etc/Chrystoki.conf
    }

{{- if .Values.hsm.enabled }}
lunaclient
{{- end }}