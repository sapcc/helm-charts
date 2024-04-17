{{- define "keppel_image" -}}
  {{- if contains "DEFINED" $.Values.keppel.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/keppel:{{$.Values.keppel.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "keppel_environment" }}
- name:  KEPPEL_DEBUG
  value: 'false'
- name:  KEPPEL_API_LISTEN_ADDRESS
  value: ':80'
{{- if $.Values.keppel.anycast_domain_name }}
- name:  KEPPEL_API_ANYCAST_FQDN
  value: '{{$.Values.keppel.anycast_domain_name}}'
{{- end }}
{{- if (index $.Values.keppel "anycast_issuer_key.pem") }}
- name:  KEPPEL_ANYCAST_ISSUER_KEY
  value: '/etc/keppel-keys/anycast-issuer-key.pem'
{{- end }}
{{- if (index .Values.keppel "anycast_previous_issuer_key.pem") }}
- name:  KEPPEL_ANYCAST_PREVIOUS_ISSUER_KEY
  value: '/etc/keppel-keys/anycast-previous-issuer-key.pem'
{{- end }}
- name:  KEPPEL_API_PUBLIC_FQDN
  value: 'keppel.{{$.Values.global.region}}.{{$.Values.global.tld}}'
- name:  KEPPEL_AUDIT_SILENT
  value: "true" # because hermes-rabbitmq connection is enabled
- name:  KEPPEL_AUDIT_RABBITMQ_QUEUE_NAME
  value: notifications.info
- name: KEPPEL_AUDIT_RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: rabbitmq_username
- name: KEPPEL_AUDIT_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: rabbitmq_password
- name: KEPPEL_AUDIT_RABBITMQ_HOSTNAME
  value: hermes-rabbitmq-notifications.hermes.svc
- name:  KEPPEL_BURST_ANYCAST_BLOB_PULL_BYTES
  value: '4718592000' # 4500 MiB per account (see below, near the corresponding ratelimit, for rationale)
- name:  KEPPEL_BURST_BLOB_PULLS # burst budgets for regular pull/push are all ~30% of the rate limit per minute
  value: '300' # per account
- name:  KEPPEL_BURST_BLOB_PUSHES
  value: '30'  # per account
- name:  KEPPEL_BURST_MANIFEST_PULLS
  value: '300'  # per account
- name:  KEPPEL_BURST_MANIFEST_PUSHES
  value: '15'   # per account
- name:  KEPPEL_BURST_TRIVY_REPORT_RETRIEVALS
  value: '50'   # per account
- name: KEPPEL_DB_USERNAME
  value: 'keppel'
- name:  KEPPEL_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-keppel'
      key: 'postgres-password'
- name: KEPPEL_DB_HOSTNAME
  value: "{{ .Release.Name }}-postgresql"
- name: KEPPEL_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name:  KEPPEL_DRIVER_AUTH
  value: 'keystone'
- name:  KEPPEL_DRIVER_FEDERATION
  value: 'swift'
- name:  KEPPEL_DRIVER_INBOUND_CACHE
  value: 'swift'
- name:  KEPPEL_DRIVER_RATELIMIT
  value: 'basic'
- name:  KEPPEL_DRIVER_STORAGE
  value: 'swift'
- name:  KEPPEL_FEDERATION_OS_AUTH_URL
  value: "https://identity-3.{{ $.Values.federation.leader_region }}.{{ $.Values.global.tld }}/v3"
- name:  KEPPEL_FEDERATION_OS_AUTH_VERSION
  value: '3'
- name:  KEPPEL_FEDERATION_OS_IDENTITY_API_VERSION
  value: '3'
- name:  KEPPEL_FEDERATION_OS_INTERFACE
  value: public
- name:  KEPPEL_FEDERATION_OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: federation_service_user_password
- name:  KEPPEL_FEDERATION_OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name:  KEPPEL_FEDERATION_OS_PROJECT_NAME
  value: 'master'
- name:  KEPPEL_FEDERATION_OS_REGION_NAME
  value: {{ quote $.Values.federation.leader_region }}
- name:  KEPPEL_FEDERATION_OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  KEPPEL_FEDERATION_OS_USERNAME
  value: 'keppel'
- name:  KEPPEL_FEDERATION_SWIFT_CONTAINER
  value: 'keppel_federation_db'
- name:  KEPPEL_GUI_URI
  value: {{ quote $.Values.keppel.dashboard_url_pattern }}
- name:  KEPPEL_INBOUND_CACHE_EXCEPT_HOSTS
  value: "keppel\\..+"
- name:  KEPPEL_INBOUND_CACHE_OS_AUTH_URL
  value: "https://identity-3.{{ $.Values.federation.leader_region }}.{{ $.Values.global.tld }}/v3"
- name:  KEPPEL_INBOUND_CACHE_OS_AUTH_VERSION
  value: '3'
- name:  KEPPEL_INBOUND_CACHE_OS_IDENTITY_API_VERSION
  value: '3'
- name:  KEPPEL_INBOUND_CACHE_OS_INTERFACE
  value: public
- name:  KEPPEL_INBOUND_CACHE_OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: federation_service_user_password
- name:  KEPPEL_INBOUND_CACHE_OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name:  KEPPEL_INBOUND_CACHE_OS_PROJECT_NAME
  value: 'master'
- name:  KEPPEL_INBOUND_CACHE_OS_REGION_NAME
  value: {{ quote $.Values.federation.leader_region }}
- name:  KEPPEL_INBOUND_CACHE_OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  KEPPEL_INBOUND_CACHE_OS_USERNAME
  value: 'keppel'
- name:  KEPPEL_INBOUND_CACHE_SWIFT_CONTAINER
  value: 'keppel_inbound_cache'
- name:  KEPPEL_ISSUER_KEY
  value: '/etc/keppel-keys/issuer-key.pem'
{{- if (index .Values.keppel "previous_issuer_key.pem") }}
- name:  KEPPEL_PREVIOUS_ISSUER_KEY
  value: '/etc/keppel-keys/previous-issuer-key.pem'
{{- end }}
- name:  KEPPEL_JANITOR_LISTEN_ADDRESS
  value: ':80'
- name:  KEPPEL_OSLO_POLICY_PATH
  value: '/etc/keppel/policy.yaml'
- name:  KEPPEL_PEERS
  value: "{{ range .Values.keppel.peers }}{{ .hostname }},{{ end }}"
- name:  KEPPEL_RATELIMIT_ANYCAST_BLOB_PULL_BYTES
  value: '5242880 B/s' # 5 MiB/s per account (very small to discourage continuous use of anycast, but
                       # the burst budget is very large to enable anycast pulling of large images; the
                       # actual burst budget is 4500 MiB, which is 15 minutes worth of rate limit)
- name:  KEPPEL_RATELIMIT_BLOB_PULLS
  value: '1000r/m' # per account
- name:  KEPPEL_RATELIMIT_BLOB_PUSHES
  value: '100r/m'  # per account
- name:  KEPPEL_RATELIMIT_MANIFEST_PULLS
  value: '1000r/m'  # per account (used to be smaller than rate limit for blob pulls, but we pulled
                    # it up to account for clients that just poll the state of certain tags without
                    # actually pulling the image contents)
- name:  KEPPEL_RATELIMIT_MANIFEST_PUSHES
  value: '10r/m'   # per account
- name:  KEPPEL_RATELIMIT_TRIVY_REPORT_RETRIEVALS
  value: '10r/m'   # per account
- name: KEPPEL_REDIS_ENABLE
  value: '1'
- name: KEPPEL_REDIS_HOSTNAME
  value: "{{ .Release.Name }}-redis"
- name: KEPPEL_REDIS_PORT
  value: '6379' # this is the default, but we need to set it to ensure that Kubernetes does not autofill this variable with its service-discovery stuff
- name: KEPPEL_REDIS_DB_NUM
  value: '1'
- name: KEPPEL_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: redis_password
{{- if .Values.keppel.trivy.hostname }}
- name: KEPPEL_TRIVY_ADDITIONAL_PULLABLE_REPOS
  value: "ccloud-ghcr-io-mirror/aquasecurity/trivy-db,ccloud-ghcr-io-mirror/aquasecurity/trivy-java-db"
- name: KEPPEL_TRIVY_URL
  value: "https://{{ .Values.keppel.trivy.hostname }}"
- name: KEPPEL_TRIVY_TOKEN
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: trivy_token
{{- end }}
- name:  OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: internal
- name:  OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: service_user_password
- name:  OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name:  OS_PROJECT_NAME
  value: 'cloud_admin'
- name:  OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'keppel'
{{- end -}}

{{- define "tmplKeepImagePulled" -}}
          imagePullPolicy: IfNotPresent
          command: [ '/bin/sleep', 'inf' ]
          securityContext:
            runAsNonRoot: true
            runAsUser:    65534 # nobody
            runAsGroup:   65534 # nobody
          resources:
            requests:
              cpu: "1m"
              memory: "32Mi"
            limits:
              cpu: "1m"
              memory: "32Mi"
{{- end -}}
