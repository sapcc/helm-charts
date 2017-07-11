those files are used as input to the snmp-exporter generator (https://github.com/prometheus/snmp_exporter/tree/master/generator) to generate the corresponding _snmp-exporter-<module-name>.yaml.tpl files - for example:

cp demo1-generator.yaml generator.yml
<path-to-generator>/generator generate
# this prefixes the metric names with snmp_
perl -p -e 's,-\ name:\ ,-\ name:\ snmp_,g' snmp.yml > ../../templates/_snmp-exporter-demo1.yaml.tpl

for this to work the following section has to exist in the secrets file:

snmp_exporter:
  enabled: True
  docker_repo: prom/snmp-exporter
  maia_snmp_config:
    - name: demo1
      default:
      username: demo1
      password: password1
      auth_protocol: MD5
      priv_protocol: DES
      security_level: authPriv
      priv_password: password1
      target: snmp-device-name-or-ip
