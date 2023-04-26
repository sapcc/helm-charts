Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/openstack/bin"
cinder ALL=(root) NOPASSWD: /var/lib/openstack/bin/cinder-rootwrap /etc/cinder/rootwrap.conf *
cinder ALL=(root) NOPASSWD: /var/lib/openstack/bin/cinder-rootwrap-daemon /etc/cinder/rootwrap.conf *
