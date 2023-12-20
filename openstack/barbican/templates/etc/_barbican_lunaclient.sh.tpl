#!/bin/bash
set -ex

lunaclient () {
    NOW="$(date +%Y%m%d)"
    cp /thales/safenet/lunaclient/Chrystoki-template.conf /thales/safenet/lunaclient/config/Chrystoki.conf
    ln -s /thales/safenet/lunaclient/libs/64/libCryptoki2.so /usr/lib/libcrystoki2.so
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

    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Label -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Label }}
    {{- if eq .Values.hsm.ha.enabled true }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00SN -v 1{{ .Values.lunaclient.VirtualToken.VirtualToken00SN }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Members -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Members }},{{ .Values.lunaclient.VirtualToken.VirtualToken00Members02 }}
    {{- else}}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00SN -v {{ .Values.lunaclient.VirtualToken.VirtualToken00SN }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualToken00Members -v {{ .Values.lunaclient.VirtualToken.VirtualToken00Members }}
    {{- end}}

    /thales/safenet/lunaclient/bin/64/configurator setValue -s "VirtualToken" -e VirtualTokenActiveRecovery -v {{ .Values.lunaclient.VirtualToken.VirtualTokenActiveRecovery }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HASynchronize" -e {{ .Values.lunaclient.VirtualToken.VirtualToken00Label }} -v {{ .Values.lunaclient.HASynchronize.sync }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e haLogStatus -v {{ .Values.lunaclient.HAConfiguration.haLogStatus }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e reconnAtt -v {{ .Values.lunaclient.HAConfiguration.reconnAtt }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e HAOnly -v {{ .Values.lunaclient.HAConfiguration.HAOnly }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e haLogPath -v {{ .Values.lunaclient.HAConfiguration.haLogPath }}
    /thales/safenet/lunaclient/bin/64/configurator setValue -s "HAConfiguration" -e logLen -v {{ .Values.lunaclient.HAConfiguration.logLen }}
    /thales/safenet/lunaclient/bin/64/vtl createCert -n $HOSTNAME-$NOW

    #REGISTER HSM1
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd }} /thales/safenet/lunaclient/config/certs/$HOSTNAME-$NOW.pem {{ .Values.lunaclient.conn.user }}@{{ .Values.lunaclient.conn.ip }}:.
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd }} {{ .Values.lunaclient.conn.user }}@{{ .Values.lunaclient.conn.ip }}:server.pem /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/vtl addserver -n {{ .Values.lunaclient.conn.ip }} -c  /thales/safenet/lunaclient/config/certs/server.pem
    echo "client register -c $HOSTNAME-$NOW" -h $HOSTNAME-$NOW > /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    echo "client assignPartition -c $HOSTNAME-$NOW -p {{ .Values.lunaclient.conn.par }}" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    echo "exit" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    /thales/safenet/lunaclient/bin/64/plink {{ .Values.lunaclient.conn.ip }} -ssh -l {{ .Values.lunaclient.conn.user }} -pw {{ .Values.lunaclient.conn.pwd }} -v < /thales/safenet/lunaclient/config/$HOSTNAME-$NOW.txt
    
    {{- if eq .Values.hsm.ha.enabled true }}
    #REGISTER HSM2
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd }} /thales/safenet/lunaclient/config/certs/$HOSTNAME-$NOW.pem {{ .Values.lunaclient.conn.user }}@{{ .Values.lunaclient.conn.ip02 }}:.
    /thales/safenet/lunaclient/bin/64/pscp -pw {{ .Values.lunaclient.conn.pwd }} {{ .Values.lunaclient.conn.user }}@{{ .Values.lunaclient.conn.ip02 }}:server.pem /thales/safenet/lunaclient/config/certs/
    /thales/safenet/lunaclient/bin/64/vtl addserver -n {{ .Values.lunaclient.conn.ip02 }} -c  /thales/safenet/lunaclient/config/certs/server.pem
    echo "client register -c $HOSTNAME-$NOW" -h $HOSTNAME-$NOW > /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    echo "client assignPartition -c $HOSTNAME-$NOW -p {{ .Values.lunaclient.conn.par02 }}" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    echo "exit" >> /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    /thales/safenet/lunaclient/bin/64/plink {{ .Values.lunaclient.conn.ip02 }} -ssh -l {{ .Values.lunaclient.conn.user }} -pw {{ .Values.lunaclient.conn.pwd }} -v < /thales/safenet/lunaclient/config/$HOSTNAME-$NOW-02.txt
    {{- end}}
    
    cp /thales/safenet/lunaclient/config/Chrystoki.conf /etc/Chrystoki.conf
    }

{{- if eq .Values.hsm.enabled true }}
lunaclient
{{- end }}
