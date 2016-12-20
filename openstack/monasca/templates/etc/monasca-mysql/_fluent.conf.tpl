{{- define "monasca_mysql_fluent_conf_tpl" -}}
<source>
  @type tail
  path /var/log/mysql/mysql.log,/var/log/mysql/mysql-slow.log,/var/log/mysql/error.log
  pos_file /var/log/mysql/mysql.log.pos
  tag mysql
  format none
</source>

<match mysql>
  @type stdout
</match>
{{ end }}
