{{- define "cc-shoots-compute.kvmIgnition" }}
storage:
  files:
  {{- if eq .workerChannel "preRelease" }}
  {{- if and .worker.extraIgnitionFiles ( typeIs "string" .worker.extraIgnitionFiles ) }}
  {{- .worker.extraIgnitionFiles | nindent 16 }}
  {{- end }}
  {{- end }}
  {{- if and ( eq .workerChannel "preRelease" ) .worker.defaultIgnitionFiles ( typeIs "string" .worker.defaultIgnitionFiles ) }}
  {{- .worker.defaultIgnitionFiles | nindent 16 }}
  {{- else }}

  - path: /etc/default/openvswitch-switch
    filesystem: root
    mode: 0644
    overwrite: true
    contents:
      inline: |
        OVS_CTL_OPTS="--ovs-user='root:openvswitch'"

  - path: /etc/polkit-1/rules.d/00-kvm-node-agent.rules
    overwrite: true
    mode: 0644
    contents:
      inline: |
        // Allow kvm-node-agent to manage specific service units;
        // fall back to implicit authorization otherwise.

        const units = ["libvirtd", "virt-admin"];
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "kvm-node-agent" &&
            units.filter(function (unit) { return action.lookup("unit").startsWith(unit) }).length ) {
                return polkit.Result.YES;
            }
        });

  - path: /etc/systemd/logind.conf.d/00-inhibit-delay-10min.conf
    overwrite: yes
    mode: 0644
    contents:
      inline: |
        [Login]
        # Set the maximum delay for the inhibit delay to 10 minutes
        # to give enough time to emergency evacuate the node
        InhibitDelayMaxSec=600

  - path: /etc/multipath.conf
    overwrite: yes
    mode: 0644
    contents:
      inline: |
        defaults {
          user_friendly_names         no
          find_multipaths             yes
          prio                        "alua"
          path_grouping_policy        group_by_prio
          path_selector               "historical-service-time 0"
          failback                    immediate
          no_path_retry               1
          retain_attached_hw_handler  yes
        }

        blacklist {
          protocol scsi:sas
          protocol scsi:ata
          protocol nvme:pcie
        }

        devices {
          device {
            vendor              "NETAPP"
            product             "*"
            hardware_handler    "1 alua"
          }
        }

  - path: /opt/persist/hugepages.env
    overwrite: yes
    mode: 0644
    contents:
      inline: |
        ENABLE_HUGEPAGE_SETUP=true

  - path: /etc/libvirt/libvirt.conf
    overwrite: yes
    mode: 0644
    contents:
      inline: |
        {{- if eq (default .root.Values.workerDefaults.feature .worker.feature) "qemu" }}
        uri_default = "qemu:///system"
        {{- else }}
        uri_default = "ch:///system"
        {{- end }}

  - path: /etc/libvirt/libvirtd.conf
    overwrite: yes
    mode: 0600
    contents:
      inline: |
        tls_priority = "NORMAL:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1"

  {{- if coalesce (.worker.coredump).enabled (.cluster.coredump).enabled .root.Values.coredump.enabled }}
  - path: /etc/systemd/coredump.conf.d/90-qa.conf
    overwrite: yes
    mode: 0600
    contents:
      inline: |
        [Coredump]
        Storage=external
        Compress=yes
        ExternalSizeMax=32G

  - path: /etc/systemd/system.conf.d/90-qa.conf
    overwrite: yes
    mode: 0600
    contents:
      inline: |
        [Manager]
        DefaultLimitCORE=
  {{- end }}
  {{- end }}

systemd:
  units:
  {{- if eq .workerChannel "preRelease" }}
  {{- if and .worker.extraIgnitionSystemdUnits ( typeIs "string" .worker.extraIgnitionSystemdUnits ) }}
  {{- .worker.extraIgnitionSystemdUnits | nindent 16 }}
  {{- end }}
  {{- end }}
  {{- if and ( eq .workerChannel "preRelease" ) .worker.defaultIgnitionSystemdUnits ( typeIs "string" .worker.defaultIgnitionSystemdUnits ) }}
  {{- .worker.defaultIgnitionSystemdUnits | nindent 16 }}
  {{- else }}
  - name: ovsdb-server.service
    dropins:
      - name: allow-group.conf
        contents: |
          [Service]
          UMask=0002
          RuntimeDirectoryMode=0775

  - name: libvirtd.service
    dropins:
      - name: want-tls-socket.conf
        contents: |
          [Unit]
          Wants=libvirtd-tls.socket
          After=libvirtd-tls.socket
      - name: tls-cert-condition.conf
        contents: |
          [Unit]
          ConditionPathExists=/etc/pki/libvirt/clientcert.pem
          ConditionPathExists=/etc/pki/libvirt/private/clientkey.pem
          {{- if eq (default .root.Values.workerDefaults.feature .worker.feature) "qemu" }}
          ConditionPathExists=/etc/pki/qemu/client-cert.pem
          ConditionPathExists=/etc/pki/qemu/client-key.pem
          {{- end }}

  - name: libvirtd.socket
    dropins:
      - name: no-trigger-limit.conf
        contents: |
          [Socket]
          TriggerLimitIntervalSec=0
      - name: require-tls-certs.conf
        contents: |
          [Unit]
          ConditionPathExists=/etc/pki/libvirt/clientcert.pem
          ConditionPathExists=/etc/pki/libvirt/private/clientkey.pem
          {{- if eq (default .root.Values.workerDefaults.feature .worker.feature) "qemu" }}
          ConditionPathExists=/etc/pki/qemu/client-cert.pem
          ConditionPathExists=/etc/pki/qemu/client-key.pem
          {{- end }}

  - name: libvirtd-tls.socket
    dropins:
      - name: require-tls-certs.conf
        contents: |
          [Unit]
          ConditionPathExists=/etc/pki/libvirt/clientcert.pem
          ConditionPathExists=/etc/pki/libvirt/private/clientkey.pem
          {{- if eq (default .root.Values.workerDefaults.feature .worker.feature) "qemu" }}
          ConditionPathExists=/etc/pki/qemu/client-cert.pem
          ConditionPathExists=/etc/pki/qemu/client-key.pem
          {{- end }}

  - name: libvirtd-tcp.socket
    mask: true

  - name: virt-admin-server-update-tls.service
    enabled: false
    contents: |
      [Unit]
      Description=Run virt-admin server-update-tls
      Documentation=man:virt-admin(1)
      Wants=libvirtd.service
      After=libvirtd.service
      ConditionVirtualization=!container
      ConditionPathExists=/etc/pki/libvirt/clientcert.pem
      ConditionPathExists=/etc/pki/libvirt/private/clientkey.pem
      {{- if eq (default .root.Values.workerDefaults.feature .worker.feature) "qemu" }}
      ConditionPathExists=/etc/pki/qemu/client-cert.pem
      ConditionPathExists=/etc/pki/qemu/client-key.pem
      {{- end }}

      [Service]
      Type=oneshot
      ExecStart=/usr/bin/virt-admin server-update-tls --server libvirtd

  - name: ovs-br-ex.service
    enabled: true
    contents: |
      [Unit]
      Description=Create OVS bridge for external network
      DefaultDependencies=no
      Wants=ovsdb-server.service
      Wants=ovs-vswitchd.service
      After=ovsdb-server.service
      After=ovs-vswitchd.service
      Before=network-online.target
      PartOf=network.target

      [Service]
      Type=oneshot
      ExecStart=/usr/bin/ovs-vsctl -- --may-exist add-br br-ex
      ExecStartPost=-/usr/bin/ip link set br-ex up
      RemainAfterExit=yes
      TimeoutSec=0
      StandardOutput=journal

      [Install]
      WantedBy=default.target
  {{- end }}
{{- end -}}
