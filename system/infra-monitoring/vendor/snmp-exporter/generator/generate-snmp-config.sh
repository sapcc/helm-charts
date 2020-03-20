#!/bin/bash
#set -x

if [[ $# -eq 0 ]] ; then
    echo 'Please set the module name like "asr" or "all" to create snmp config'
    exit 1
fi

if [ $1 = "all" ]; then

   export modules=`ls  ../_snmp-exporter-*|awk -F- '{ print $3}'|awk -F. '{ print $1}'`

else
   export modules=`ls  ../_snmp-exporter-*|awk -F- '{ print $3}'|awk -F. '{ print $1}'`
   echo $modules |grep -qw $1

   if [ $? -eq 0 ] ; then

   export modules=$1

   else 
   echo "no module named $1"
   exit 1
   fi

fi

cd
#git clone https://github.com/sapcc/helm-charts.git
cd /root/helm-charts/system/infra-monitoring/vendor/snmp-exporter/generator/


for i in $modules;

  do
        cp -f ./${i}-generator.yaml ./generator.yml
        echo "##############################################"
        echo "############### config for ${i} ##############"
        echo "##############################################"
 
        /gopath/bin/generator generate || exit


        mv -f ./snmp.yml ./_snmp-exporter-${i}.yaml.tmp
        rm -d ./generator.yml

        if test -f "${i}-additional-oids.yaml"; then
            awk -v f=$i '{ print; } /walk:/ { system ( "cat "f"-additional-oids.yaml" ) } \' _snmp-exporter-${i}.yaml.tmp  > ../_snmp-exporter-${i}.yaml
        else
            mv -f ./_snmp-exporter-${i}.yaml.tmp ../_snmp-exporter-${i}.yaml
        fi
 
        if [[ "$i" =~ ^(f5mgmt|f5physical|f5customer)$ ]]; then
            sed -i "s/- name: /- name: snmp_f5_/g" ../_snmp-exporter-${i}.yaml
        else
            sed -i "s/- name: /- name: snmp_${i}_/g" ../_snmp-exporter-${i}.yaml
        fi
 
        if test -f "${i}-additional-metrics.yaml"; then
                cat ${i}-additional-metrics.yaml >> ../_snmp-exporter-${i}.yaml
                rm -f ./_snmp-exporter-${i}.yaml.tmp
        fi
done


if grep -q "arista:" ../_snmp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-exporter-arista.yaml
fi

if grep -q "n7k:" ../_snmp-exporter-n7k.yaml; then
    sed -i '2d' ../_snmp-exporter-n7k.yaml
fi

if grep -q "n7k:" ../_snmp-exporter-n7kcontext.yaml; then
    sed -i '2d' ../_snmp-exporter-n7kcontext.yaml
fi

if grep -q "asw:" ../_snmp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-exporter-arista.yaml
fi
