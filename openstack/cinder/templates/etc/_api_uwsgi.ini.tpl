[uwsgi]
need-app = true
http-socket = :{{ .Values.cinderApiPortInternal }}
uid = root
gid = root
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
processes = {{ .Values.api.workers }}
wsgi-file = /var/lib/openstack/bin/cinder-wsgi
