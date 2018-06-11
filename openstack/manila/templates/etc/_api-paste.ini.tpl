#############
# OpenStack #
#############

[composite:osapi_share]
use = call:manila.api:root_app_factory
/: apiversions
/v1: openstack_share_api
/v2: openstack_share_api_v2

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

[composite:openstack_share_api]
use = call:manila.api.middleware.auth:pipeline_factory
noauth = cors faultwrap http_proxy_to_wsgi sizelimit noauth api
keystone = cors faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "audit_pipe" . }} api
keystone_nolimit = cors faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "audit_pipe" . }} api

[composite:openstack_share_api_v2]
use = call:manila.api.middleware.auth:pipeline_factory
noauth = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit noauth apiv2
keystone = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "audit_pipe" . }} apiv2
keystone_nolimit = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "audit_pipe" . }} apiv2

[filter:faultwrap]
paste.filter_factory = manila.api.middleware.fault:FaultWrapper.factory

[filter:noauth]
paste.filter_factory = manila.api.middleware.auth:NoAuthMiddleware.factory

[filter:sizelimit]
paste.filter_factory = oslo_middleware.sizelimit:RequestBodySizeLimiter.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

[app:api]
paste.app_factory = manila.api.v1.router:APIRouter.factory

[app:apiv2]
paste.app_factory = manila.api.v2.router:APIRouter.factory

[pipeline:apiversions]
pipeline = cors faultwrap http_proxy_to_wsgi osshareversionapp

[app:osshareversionapp]
paste.app_factory = manila.api.versions:VersionsRouter.factory

##########
# Shared #
##########

[filter:keystonecontext]
paste.filter_factory = manila.api.middleware.auth:ManilaKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = manila

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

{{ if .Values.audit.enabled -}}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/manila/manila_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end -}}
