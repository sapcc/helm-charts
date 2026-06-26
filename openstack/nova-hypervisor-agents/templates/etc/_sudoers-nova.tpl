Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/lib/openstack/bin"

nova ALL=(root) NOPASSWD: /var/lib/openstack/bin/nova-rootwrap /etc/nova/rootwrap.conf *
nova ALL=(root) NOPASSWD: /var/lib/openstack/bin/nova-rootwrap-daemon /etc/nova/rootwrap.conf *
