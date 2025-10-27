[DEFAULT]
debug = True
host = 0.0.0.0
port = {{ .Values.vspc.telnet.portInternal }}
web_port = {{ .Values.vspc.web.portInternal }}
# cert = cert.pem
# key = key.pem
uri = {{ .Values.vspc.url }}
serial_log_dir = /var/run/serial_log_dir

