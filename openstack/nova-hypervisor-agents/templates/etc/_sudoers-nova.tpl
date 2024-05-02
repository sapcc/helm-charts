Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/openstack/bin:/var/lib/kolla/venv/bin"

nova ALL=(root) NOPASSWD: /var/lib/openstack/bin/nova-rootwrap /etc/nova/rootwrap.conf *
nova ALL=(root) NOPASSWD: /var/lib/openstack/bin/nova-rootwrap-daemon /etc/nova/rootwrap.conf *
