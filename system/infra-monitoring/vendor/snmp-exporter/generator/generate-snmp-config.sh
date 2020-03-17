#!/bin/bash
#set -x

cd
#git clone https://github.com/sapcc/helm-charts.git
cd /root/helm-charts/system/infra-monitoring/vendor/snmp-exporter/generator/

export modules=`ls  ../_snmp-exporter-*|awk -F- '{ print $3}'|awk -F. '{ print $1}'`

for i in $(ls  ../_snmp-exporter-*|awk -F- '{ print $3}'|awk -F. '{ print $1}');
do
    cp -f ./${i}-generator.yaml ./generator.yml
        /gopath/bin/generator generate
                echo "##############################################"
                echo "############### config for ${i} ##############"
                echo "##############################################"
        mv -f ./snmp.yml ./_snmp-exporter-${i}.yaml.tmp
        if test -f "${i}-additional-oids.yaml"; then
            awk -v f=$i '{ print; } /walk:/ { system ( "cat "f"-additional-oids.yaml" ) } \' _snmp-exporter-${i}.yaml.tmp  > ../_snmp-exporter-${i}.yaml
            sed -i "s/- name: /- name: snmp_${i}_/g" ../_snmp-exporter-${i}.yaml
        else
            mv -f ./_snmp-exporter-${i}.yaml.tmp ../_snmp-exporter-${i}.yaml
            sed -i "s/- name: /- name: snmp_${i}_/g" ../_snmp-exporter-${i}.yaml
    fi

        if test -f "${i}-additional-metrics.yaml"; then
                cat ${i}-additional-metrics.yaml >> ../_snmp-exporter-${i}.yaml
                rm -f ./_snmp-exporter-${i}.yaml.tmp
        fi
done

sed -i '2d' ../_snmp-exporter-arista.yaml
sed -i '2d' ../_snmp-exporter-n7k.yaml

