{{- define "monasca_zookeeper_cluster_zoo_cfg_tpl" -}}
dataDir=/var/lib/zookeeper/data
dataLogDir=/var/lib/zookeeper/datalogs
standaloneEnabled=false
autopurge.purgeInterval=12
autopurge.snapRetainCount=10
tickTime=2000
initLimit=10
syncLimit=5
clientPort={{.Values.monasca_zookeeper_port_internal}}
maxClientCnxns=60
sasl.client=false
dynamicConfigFile=/conf-dir/zoo.cfg.dynamic
{{ end }}
