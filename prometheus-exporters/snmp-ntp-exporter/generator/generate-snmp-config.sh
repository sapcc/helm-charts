#!/bin/bash
#set -x

if [[ $# -eq 0 ]] ; then
    echo 'Please set the module name like "asr" or "all" to create snmp config'
    exit 1
fi

if [ $1 = "all" ]; then

   export modules=`ls  ../_snmp-ntp-exporter-*|awk -F- '{ print $4}'|awk -F. '{ print $1}'`

else
   export modules=`ls  ../_snmp-ntp-exporter-*|awk -F- '{ print $4}'|awk -F. '{ print $1}'`
   echo $modules |grep -qw $1

   if [ $? -eq 0 ] ; then

   export modules=$1

   else 
   echo "no module named $1"
   exit 1
   fi

fi

# cd
#git clone https://github.com/sapcc/helm-charts.git
# cd ./helm-charts/prometheus-exporters/snmp-ntp-exporter/generator/


mv /usr/share/snmp/mibs/CISCO-UNIFIED-COMPUTING-TC-MIB.mib /usr/share/snmp/ # This mib makes other generators fail...

for i in $modules;

    
  do
        cp -f ./${i}-generator.yaml ./generator.yml
        echo "##############################################"
        echo "############### config for ${i} ##############"
        echo "##############################################"
 
        if [ $i = "ucs" ]; then # This mib makes other generators fail...
            mv /usr/share/snmp/CISCO-UNIFIED-COMPUTING-TC-MIB.mib /usr/share/snmp/mibs/
        fi

        /gopath/bin/generator generate || exit

        if [ $i = "ucs" ]; then # This mib makes other generators fail...
            mv /usr/share/snmp/mibs/CISCO-UNIFIED-COMPUTING-TC-MIB.mib /usr/share/snmp/
        fi

        mv -f ./snmp.yml ./_snmp-ntp-exporter-${i}.yaml.tmp
        rm -d ./generator.yml

        if test -f "${i}-additional-oids.yaml"; then
            awk -v f=$i '{ print; } /walk:/ { system ( "cat "f"-additional-oids.yaml" ) } \' _snmp-ntp-exporter-${i}.yaml.tmp  > ../_snmp-ntp-exporter-${i}.yaml
        else
            mv -f ./_snmp-ntp-exporter-${i}.yaml.tmp ../_snmp-ntp-exporter-${i}.yaml
        fi
 
        if [[ "$i" =~ ^(f5mgmt|f5physical|f5customer)$ ]]; then
            sed -i "s/- name: /- name: snmp_f5_/g" ../_snmp-ntp-exporter-${i}.yaml
        else
            sed -i "s/- name: /- name: snmp_${i}_/g" ../_snmp-ntp-exporter-${i}.yaml
        fi
 
        if test -f "${i}-additional-metrics.yaml"; then
                cat ${i}-additional-metrics.yaml >> ../_snmp-ntp-exporter-${i}.yaml
                rm -f ./_snmp-ntp-exporter-${i}.yaml.tmp
        fi
done


if grep -q "arista:" ../_snmp-ntp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-ntp-exporter-arista.yaml
fi

if grep -q "n7k:" ../_snmp-ntp-exporter-n7k.yaml; then
    sed -i '2d' ../_snmp-ntp-exporter-n7k.yaml
fi

if grep -q "n7k:" ../_snmp-ntp-exporter-n7kcontext.yaml; then
    sed -i '2d' ../_snmp-ntp-exporter-n7kcontext.yaml
fi

if grep -q "asw:" ../_snmp-ntp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-ntp-exporter-arista.yaml
fi
