[composite:main]
use = egg:Paste#urlmap
/: barbican_version
/v1: barbican_api

# Use this pipeline for Barbican API - versions no authentication
[pipeline:barbican_version]
pipeline = cors versionapp

# Use this pipeline for Barbican API - DEFAULT no authentication
[pipeline:barbican_api]
#pipeline = cors unauthenticated-context apiapp
pipeline = keystone_authtoken context apiapp

#Use this pipeline to activate a repoze.profile middleware and HTTP port,
#  to provide profiling information for the REST API processing.
[pipeline:barbican-profile]
pipeline = cors unauthenticated-context egg:Paste#cgitb egg:Paste#httpexceptions profile apiapp

#Use this pipeline for keystone auth
[pipeline:barbican-api-keystone]
pipeline = cors keystone_authtoken context apiapp

#Use this pipeline for keystone auth with audit feature
[pipeline:barbican-api-keystone-audit]
pipeline = keystone_authtoken context audit apiapp

[app:apiapp]
paste.app_factory = barbican.api.app:create_main_app

[app:versionapp]
paste.app_factory = barbican.api.app:create_version_app

[filter:simple]
paste.filter_factory = barbican.api.middleware.simple:SimpleFilter.factory

[filter:unauthenticated-context]
paste.filter_factory = barbican.api.middleware.context:UnauthenticatedContextMiddleware.factory

[filter:context]
paste.filter_factory = barbican.api.middleware.context:ContextMiddleware.factory

[filter:audit]
paste.filter_factory = keystonemiddleware.audit:filter_factory
audit_map_file = /etc/barbican/api_audit_map.conf

[filter:keystone_authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:profile]
use = egg:repoze.profile
log_filename = myapp.profile
cachegrind_filename = cachegrind.out.myapp
discard_first_request = true
path = /__profile__
flush_at_shutdown = true
unwind = false

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = barbican
