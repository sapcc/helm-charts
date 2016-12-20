{{- define "monasca_zookeeper_cluster_log4j_properties_tpl" -}}
zookeeper.root.logger=WARN, CONSOLE
log4j.rootLogger=${zookeeper.root.logger}
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold={{.Values.monasca_zookeeper_loglevel}}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
{{ end }}
