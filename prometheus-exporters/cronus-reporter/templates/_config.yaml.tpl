
{{- $app := "reporter" }}
{{- $val := .Values.reporter }}
{{- if $val.enabled -}}
{{ $app }}:
  prometheusPort: {{ $val.prometheusPort }}
  notifier:
    ec2Access: {{ .Values.secAttNotifier.awsAccess }}
    ec2Secret: {{ .Values.secAttNotifier.awsSecret }}
    smtpHost: {{ .Values.secAttNotifier.smtpHost }}
    smtpPassword: {{ .Values.secAttNotifier.smtpPassword }}
    smtpPort: {{ .Values.secAttNotifier.port }}
    sender: {{ .Values.secAttNotifier.sourceEmail }}
    sleepDuration: {{ $val.notifier.sleepDuration }}
  {{- if $val.lineOfBusiness }}
  lineOfBusiness: 
    {{- range $lob := $val.lineOfBusiness }}
    - name: {{ $lob.name }}
      {{- if $lob.contacts }}
      contacts:
        {{- range $contact := $lob.contacts }}
        - {{$contact | quote }}
        {{- end }}
      {{- end }}
      {{- if $lob.reports }}
      reports:
        {{- range $report := $lob.reports }}
        - {{$report | quote }}
        {{- end }}
      {{- end }}
      {{- if $lob.accounts }}
      accounts:
        {{- range $account := $lob.accounts }}
          {{- if $account.projectName }}
        - projectName: {{ $account.projectName | quote }}
          {{- end }}
          {{- if $account.amazonId }}
          amazonId: {{ $account.amazonId | quote }}
          {{- end }}
          {{- if $account.projectId }}
          projectId: {{ $account.projectId | quote }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  keystoneCredentials:
    region: {{ .Values.config.keystone.region }}
    applicationCredentialsProject: {{ .Values.updater.applicationCredentialsProject }}
    applicationCredentialsDomain: {{ .Values.updater.applicationCredentialsDomain }}
    applicationCredentialsName: {{ .Values.updater.applicationCredentialsName }}
    applicationCredentialsSecret: {{ .Values.updater.applicationCredentialsSecret }}
    applicationCredentialsId: {{ .Values.updater.applicationCredentialsId }}
  awsConfig:
    awsRegion: {{ .Values.config.allowedServices.email }}
    awsAccess: {{ .Values.config.awsAccess }}
    awsSecret: {{ .Values.config.awsSecret }}
{{- end }}
