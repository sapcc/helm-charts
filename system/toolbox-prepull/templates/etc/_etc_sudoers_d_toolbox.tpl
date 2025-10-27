# Toolbox
%{{ .Values.supporToolbox.ldapGroup }} ALL=(root:root) NOPASSWD: {{ .Values.supporToolbox.path }}
%{{ .Values.supporToolbox.ldapGroup }} ALL=(root:root) NOPASSWD: /usr/sbin/blkid
%{{ .Values.supporToolbox.ldapGroup }} ALL=(root:root) NOPASSWD: /usr/sbin/dmsetup
%{{ .Values.supporToolbox.ldapGroup }} ALL=(root:root) NOPASSWD: /usr/bin/journalctl
