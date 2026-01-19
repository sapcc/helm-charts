{{- define "keppel_image" -}}
  {{- if contains "DEFINED" $.Values.keppel.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/keppel:{{$.Values.keppel.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "keppel_environment" }}
{{- $region := $.Values.global.region | required "missing value for .Values.global.region" -}}
{{- $tld    := $.Values.global.tld    | required "missing value for .Values.global.tld"    -}}
{{- $peer_group := index $.Values.keppel.peer_groups $.Values.keppel.peer_group -}}
{{- $overrides  := merge (dict) (index $.Values.keppel.region_overrides $region | default (dict)) $.Values.keppel.region_overrides.default }}
- name:  KEPPEL_DEBUG
  value: 'false'
- name:  KEPPEL_API_LISTEN_ADDRESS
  value: ':80'
{{- if $peer_group.exclude_from_anycast | has $region | not }}
- name:  KEPPEL_API_ANYCAST_FQDN
  value: {{ quote $peer_group.anycast_domain_name }}
{{- end }}
- name:  KEPPEL_ANYCAST_ISSUER_KEY
  value: '/etc/keppel-keys/anycast-issuer-key.pem'
- name:  KEPPEL_ANYCAST_PREVIOUS_ISSUER_KEY
  value: '/etc/keppel-keys/anycast-previous-issuer-key.pem'
- name:  KEPPEL_API_PUBLIC_FQDN
  value: 'keppel.{{$region}}.{{$tld}}'
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
  value: '{"type":"keystone","params":{"oslo_policy_path":"/etc/keppel/policy.json"}}'
- name:  KEPPEL_DRIVER_FEDERATION
  value: '{"type":"swift","params":{"env_prefix":"KEPPEL_FEDERATION_","container_name":"keppel_federation_db"}}'
- name:  KEPPEL_DRIVER_INBOUND_CACHE
  value: '{"type":"swift","params":{"env_prefix":"KEPPEL_FEDERATION_","container_name":"keppel_inbound_cache","except_hosts":"keppel\\..+"}}'
- name:  KEPPEL_DRIVER_RATELIMIT
  value: {{ include "driver_config_ratelimit" $ | fromYaml | toJson | quote }}
- name:  KEPPEL_DRIVER_STORAGE
  value: '{"type":"swift"}'
- name:  KEPPEL_FEDERATION_OS_AUTH_URL
  value: "https://identity-3.{{ $peer_group.leader }}.{{ $tld }}/v3"
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
  value: {{ quote $peer_group.leader }}
- name:  KEPPEL_FEDERATION_OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  KEPPEL_FEDERATION_OS_USERNAME
  value: 'keppel'
- name:  KEPPEL_GUI_URI
  value: https://dashboard.{{ $region }}.cloud.sap/_/%AUTH_TENANT_ID%/keppel/#/repo/%ACCOUNT_NAME%/%REPO_NAME%
- name:  KEPPEL_ISSUER_KEY
  value: '/etc/keppel-keys/issuer-key.pem'
- name:  KEPPEL_PREVIOUS_ISSUER_KEY
  value: '/etc/keppel-keys/previous-issuer-key.pem'
- name:  KEPPEL_JANITOR_LISTEN_ADDRESS
  value: ':80'
- name:  KEPPEL_PEERS
  value: {{ index (include "build_peers" $ | fromYaml) "peers" | toJson | quote }}
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
      name: keppel-redis-user-default
      key: password
- name: KEPPEL_TRIVY_ADDITIONAL_PULLABLE_REPOS
  value: "ccloud-ghcr-io-mirror/aquasecurity/trivy-db,ccloud-ghcr-io-mirror/aquasecurity/trivy-java-db"
- name: KEPPEL_TRIVY_URL
  value: "https://keppel-trivy.{{ $overrides.trivy_region | default $region }}.{{ $tld }}"
- name: KEPPEL_TRIVY_TOKEN
  valueFrom:
    secretKeyRef:
      name: keppel-secret
      key: trivy_token
- name:  OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $region }}.{{ $tld }}:5000/v3"
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
  value: {{ quote $region }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'keppel'
{{- end -}}

{{- define "tmplKeepImagePulled" -}}
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

{{- define "build_peers" -}}
{{- $region := $.Values.global.region | required "missing value for .Values.global.region" -}}
{{- $tld    := $.Values.global.tld    | required "missing value for .Values.global.tld"    -}}
{{- $peer_group := index $.Values.keppel.peer_groups $.Values.keppel.peer_group -}}
peers:
{{- range $peer_region := without $peer_group.members $region }}
- hostname: keppel.{{ $peer_region }}.{{ $tld }}
{{- if $peer_group.exclude_from_pull_delegation | has $peer_region }}
  use_for_pull_delegation: false
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "driver_config_account_management" -}}
type: basic
params:
  config_path: /etc/keppel-auto-managed-accounts/config.json
  protected_accounts:
    - ccloud
    - ccloud-dockerhub-mirror
    - ccloud-gcr-mirror
    - ccloud-ghcr-io-mirror
    - ccloud-quay-mirror
    - ccloud-registry-k8s-io-mirror
    - cloud-infrastructure-ocm
{{- end -}}

{{- define "driver_config_ratelimit" -}}
type: basic
params:
  # NOTE: All limits and budgets are _per account_.
  anycast_blob_pull_bytes:
    # very small to discourage continuous use of anycast,
    # but the burst budget is very large to enable anycast pulling of large images
    limit: 5242880 # 5 MiB/s
    window: s
    burst: 4718592000 # 4500 MiB (15 minutes worth of rate limit)
  blob_pulls:
    limit: 1200
    window: m
    burst: 600
  blob_pushes:
    limit: 100
    window: m
    burst: 50
  manifest_pulls:
    limit: 1200
    window: m
    burst: 1200 # one minute worth of rate limit, because manifest requests tend to be spiky in nature
  manifest_pushes:
    limit: 10
    window: m
    burst: 15
  trivy_report_retrievals:
    # NOTE on how we derive this value:
    # - Testing has established that a single report retrieval uses about 2 ms of CPU.
    #   (pprof instrumentation gave a lower bound of 1.25ms, CPU metrics in Prometheus gave an upper bound of 2.5 ms)
    # - In productive deployments, we have 4 API pods with a limit of 500 mcpu each, so 2 CPU cores total.
    # - 2 CPU cores can sustain 1000r/s (60000r/m) if report retrievals were the only API load.
    # - Splitting that over an estimate of 100 actively used accounts gives the number above.
    limit: 600
    window: m
    burst: 600 # one minute worth of rate limit, because manifest requests tend to be spiky in nature
{{- end -}}
