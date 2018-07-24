# Use this pipeline for no auth - DEFAULT
[pipeline:glance-registry]
pipeline = healthcheck http_proxy_to_wsgi osprofiler unauthenticated-context {{ if .Values.watcher.enabled }}watcher{{ end }} registryapp

# Use this pipeline for keystone auth
[pipeline:glance-registry-keystone]
pipeline = healthcheck http_proxy_to_wsgi osprofiler authtoken context {{ if .Values.watcher.enabled }}watcher{{ end }} registryapp

# Use this pipeline for authZ only. This means that the registry will treat a
# user as authenticated without making requests to keystone to reauthenticate
# the user.
[pipeline:glance-registry-trusted-auth]
pipeline = healthcheck http_proxy_to_wsgi osprofiler context {{ if .Values.watcher.enabled }}watcher{{ end }} registryapp

[app:registryapp]
paste.app_factory = glance.registry.api:API.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/glance/healthcheck_disable

[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory

[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory
hmac_keys = SECRET_KEY  #DEPRECATED
enabled = yes  #DEPRECATED

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = image
config_file = /etc/glance/watcher.yaml
{{- end }}
