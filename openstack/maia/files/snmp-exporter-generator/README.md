those files are used as input to the snmp-exporter generator (https://github.com/prometheus/snmp_exporter/tree/master/generator) to generate the corresponding _snmp-exporter-<module-name>.yaml.tpl files - for example:

cp asr-generator.yaml generator.yml
<path-to-generator>/generator generate
# this prefixes the metric names with snmp_asr_
perl -p -e 's,-\ name:\ ,-\ name:\ snmp_asr_,g' snmp.yml > ../../templates/_snmp-exporter-asr.yaml.tpl

for this to work the following section has to exist in the secrets file (for snmp v3 auth):

snmp_exporter:
  enabled: True
  docker_repo: prom/snmp-exporter
  maia_snmp_config:
    - name: asr
      default:
      version: 3
      username: asruser
      password: asrpass
      auth_protocol: MD5
      priv_protocol: DES
      security_level: authPriv
      priv_password: asrpass
      target: 10.11.12.13
      configname: asr

or for snmp v2 auth (v1 is the same with version: 1):

...
    - name: asr
      default:
      version: 2
      community: asrcomm
      target: 10.11.12.13
      configname: asr

how to create the xyz-generator.yaml file with snmpwalk?

create a ~/.snmp/snmp.conf file for convenience (otherwise you'll need more cmdline options for the auth):

snmp v3 auth:

defSecurityName asruser
defSecurityLevel authPriv
defAuthType MD5
defPrivType DES
defAuthPassphrase asrpass
defPrivPassphrase asrpass

snmp v1/v2 auth:

defCommunity asrcomm

assuming all required mibs are installed to $HOME/.snmp/mibs the snmp tree might be queried partially (example):

snmpwalk -M $HOME/.snmp/mibs -m CISCO-IETF-NAT-MIB -v2c snmp-host 1.3.6.1.4.1.9.10.77

or completely:

snmpwalk -M $HOME/.snmp/mibs -m CISCO-IETF-NAT-MIB -v2c snmp-host .

the following will create output suitable for adding it easily to a generator.yml file:

snmpwalk -M $HOME/.snmp/mibs -m CISCO-IETF-NAT-MIB -Oq -v2c snmp-host 1.3.6.1.4.1.9.10.77 | sed 's,.*::,\ \ \ \ \ \ -\ ,g ; s,\..*,,g' | sort -u

the files *-metrics.txt contain a (incomplete)  list of metrics, which might be obtained this way. this list should just give a rough idea about them, as it is not complete and might depend on the config of the components and actual hardware as well.
