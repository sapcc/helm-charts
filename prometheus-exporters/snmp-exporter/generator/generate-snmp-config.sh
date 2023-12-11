#!/bin/bash
#set -x
export GENERATOR_PATH=/gopath/snmp_exporter/generator


if [[ $# -eq 0 ]] ; then
    echo 'Please set the module name like "asr" or "all" to create snmp config'
    exit 1
fi

if [ $1 = "all" ]; then

   export modules=`ls  ./*-generator.yaml*|awk -F- '{ print $1}'|awk -F\/ '{ print $2}'`

else
   export modules=`ls  ./*-generator.yaml*|awk -F- '{ print $1}'|awk -F\/ '{ print $2}'`
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
# cd ./helm-charts/prometheus-exporters/snmp-exporter/generator/


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

        $GENERATOR_PATH/generator generate || exit

        if [ $i = "ucs" ]; then # This mib makes other generators fail...
            mv /usr/share/snmp/mibs/CISCO-UNIFIED-COMPUTING-TC-MIB.mib /usr/share/snmp/
        fi

        mv -f ./snmp.yml ./_snmp-exporter-${i}.yaml.tmp
        rm -d ./generator.yml

        if test -f "${i}-additional-oids.yaml"; then
            awk -v f=$i '{ print; } /walk:/ { system ( "cat "f"-additional-oids.yaml" ) } \' _snmp-exporter-${i}.yaml.tmp  > ../_snmp-exporter-${i}.yaml
            sed -i '2d' ../_snmp-exporter-${i}.yaml
            rm -f  _snmp-exporter-${i}.yaml.tmp
        else
            mv -f ./_snmp-exporter-${i}.yaml.tmp ../_snmp-exporter-${i}.yaml
            sed -i '2d' ../_snmp-exporter-${i}.yaml
            rm -f  _snmp-exporter-${i}.yaml.tmp
        fi
 
        if [[ "$i" =~ ^(f5mgmt|f5physical|f5customer|f5gtm|f5archer)$ ]]; then
            sed -i "s/- name: /- name: snmp_f5_/g" ../_snmp-exporter-${i}.yaml
        else
            sed -i "s/- name: /- name: snmp_${i}_/g" ../_snmp-exporter-${i}.yaml
        fi
 
        if test -f "${i}-additional-metrics.yaml"; then
                #cat ${i}-additional-metrics.yaml >> ../_snmp-exporter-${i}.yaml
                sed  '/max_repetitions/r ${i}-additional-metrics.yaml' ../_snmp-exporter-${i}.yaml
                rm -f ./_snmp-exporter-${i}.yaml.tmp
        fi
done


if grep -q "arista:" ../_snmp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-exporter-arista.yaml
fi

if grep -q "asw:" ../_snmp-exporter-arista.yaml; then
    sed -i '2d' ../_snmp-exporter-arista.yaml
fi
