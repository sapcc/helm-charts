Those files are used as input to the snmp-exporter generator (https://github.com/prometheus/snmp_exporter/tree/master/generator) to generate the corresponding _snmp-exporter-<module-name>.yaml.tpl files - for example:


to create _snmp-exporter-<module>.yaml.tpl files, execute the following docker command and afterwards commit the changes to git. All additional oids have to be added either to the generator files or as a custom metric to the <module>-additional-metrics.yaml and <module>-additional-oids.yaml in the generator directory.

```
 docker run -v ~/github.com/sapcc/helm-charts:/root/helm-charts -ti hub.global.cloud.sap/monsoon/snmp-exporter-generator:latest bash

 cd /root/helm-charts/system/infra-monitoring/vendor/snmp-exporter/generator

 ./generate-snmp-config.sh all/<module>

or simpler:

docker run -v ~/github.com/sapcc/helm-charts:/root/helm-charts -ti hub.global.cloud.sap/monsoon/snmp-exporter-generator:lastest /start.sh all

or

docker run -v ~/github.com/sapcc/helm-charts:/root/helm-charts -ti hub.global.cloud.sap/monsoon/snmp-exporter-generator:lastest /start.sh <module>


```

commit the changes in the helm-charts repository
