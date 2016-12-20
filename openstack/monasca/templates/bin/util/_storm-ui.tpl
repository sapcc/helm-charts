{{- define "util_storm_ui_tpl" -}}
#!/bin/bash

. /container.init/common-start 

echo "Start storm UI"
/opt/storm/current/bin/storm ui
{{ end }}
