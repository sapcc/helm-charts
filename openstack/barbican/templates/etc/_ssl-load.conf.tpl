{{/*
Load mod_ssl and its socache dependency via read-only conf so the module is
available under a read-only root filesystem without a2enmod. mod_headers is
required for the HTTP security response headers set in the TLS vhost.
*/}}

LoadModule socache_shmcb_module /usr/lib/apache2/modules/mod_socache_shmcb.so
LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so
LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so
