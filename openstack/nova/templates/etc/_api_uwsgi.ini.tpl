[uwsgi]
need-app = true
http-socket = :{{ .Values.global.novaApiPortInternal }}
uid = nova
gid = nova
lazy-apps = true
add-header = Connection: close
buffer-size = 65535
hook-master-start = unix_signal:15	# gracefully_kill_them_all
thunder-lock = true
enable-threads = true
worker-reload-mercy = 90
exit-on-reload = false
die-on-term = true
master = true
memory-report = true
processes = {{ .Values.api.wsgi_processes }}
wsgi-file = /var/lib/kolla/venv/bin/nova-api-wsgi
