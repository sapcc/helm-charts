{{- define "ceph.labels" }}
- tag_name: app.label.component
  key: app.kubernetes.io/component
  from: pod
- tag_name: app.label.created-by
  key: app.kubernetes.io/created-by
  from: pod
- tag_name: app.label.managed-by
  key: app.kubernetes.io/managed-by
  from: pod
- tag_name: app.label.part-of
  key: app.kubernetes.io/part-of
  from: pod
- tag_name: app.label.ceph-osd-id
  key: ceph-osd-id
  from: pod
- tag_name: app.label.ceph_daemon_id
  key: ceph_daemon_id
  from: pod
- tag_name: app.label.ceph_daemon_type
  key: ceph_daemon_type
  from: pod
- tag_name: app.label.device-class
  key: device-class
  from: pod
- tag_name: app.label.failure-domain
  key: failure-domain
  from: pod
- tag_name: app.label.osd
  key: osd
  from: pod
- tag_name: app.label.osd-store
  key: osd-store
  from: pod
- tag_name: app.label.portable
  key: portable
  from: pod
- tag_name: app.label.rook_cluster
  key: rook_cluster
  from: pod
- tag_name: app.label.rook_io.operator-namespace
  key: rook_io/operator-namespace
  from: pod
- tag_name: app.label.topology-location-host
  key: topology-location-host
  from: pod
- tag_name: app.label.topology-location-region
  key: topology-location-region
  from: pod
- tag_name: app.label.topology-location-region
  key: topology-location-region
  from: pod
- tag_name: app.label.topology-location-root
  key: topology-location-root
  from: pod
- tag_name: app.label.topology-location-zone
  key: topology-location-zone
  from: pod
{{- end }}

{{- define "ceph.transform" }}
transform/ceph_rgw:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.component"] == "cephobjectstores.ceph.rook.io"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:log.level} %{TIMESTAMP_ISO8601:log.timestamp}(%{SPACE})?%{NOTSPACE}(%{SPACE})?%{NOTSPACE}(%{SPACE})?%{WORD}\\:(%{SPACE})?%{WORD}\\:(%{SPACE})?%{IP:client.address}(%{SPACE})?%{NOTSPACE}(%{SPACE})%{PROJECT_ID:project.id}(\\$%{NOTSPACE})?(%{SPACE})?\\[%{HTTPDATE:request.timestamp}\\] \"%{WORD:request.method} \\/(?<bucket>[a-zA-Z0-9._+-]+)?(\\/)?(%{NOTSPACE:request.path})? %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content.length:int} %{NOTSPACE} \"%{GREEDYDATA:user_agent.name}\" %{NOTSPACE} latency=%{NUMBER:latency:float}", true, ["PROJECT_ID=([A-Za-z0-9-]+)"]),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:log_level}", true),"upsert")
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower")) where cache["network.protocol.name"] != nil
        - set(log.attributes["config.parsed"], "ceph_rgw") where log.attributes["project.id"] != nil
        - set(log.attributes["config.parsed"], "ceph_rgw") where log.attributes["log.level"] != nil

transform/ceph_osd:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.component"] == "cephclusters.ceph.rook.io"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:osd.stats.level}%{SPACE}%{NOTSPACE:osd.stats.files}%{SPACE}%{NUMBER:osd.stats.osd.stats.size:float}%{SPACE}%{WORD}%{SPACE}%{NUMBER:osd.stats.size_unit:float}%{SPACE}%{NUMBER:osd.stats.score:float}%{SPACE}%{NUMBER:osd.stats.read_gb:float}%{SPACE}%{NUMBER:osd.stats.rn_gb:float}%{SPACE}%{NUMBER:osd.stats.rnp1_gb:float}%{SPACE}%{NUMBER:osd.stats.write_gb:float}%{SPACE}%{NUMBER:osd.stats.wnew_gb:float}%{SPACE}%{NUMBER:osd.stats.moved:float}%{SPACE}%{NUMBER:osd.stats.w_amp:float}%{SPACE}%{NUMBER:osd.stats.rd_mb_s:float}%{SPACE}%{NUMBER:osd.stats.wr_mb_s:float}%{SPACE}%{NUMBER:osd.stats.comp_sec:float}%{SPACE}%{NUMBER:osd.stats.comp_merge_cpu_sec:float}%{SPACE}%{NUMBER:osd.stats.cpmp_cnt:float}%{SPACE}%{NUMBER:osd.stats.av_sec:float}%{SPACE}%{NUMBER:osd.stats.keyin:float}%{SPACE}%{NUMBER:osd.stats.keydrop:float}%{SPACE}%{NUMBER:osd.stats.rblob_gb:float}%{SPACE}%{NUMBER:osd.stats.wblol_gb:float}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{GREEDYDATA:osd.wall.type}\\:%{SPACE}%{NUMBER:osd.wall.writes:float}(K|M|G)?%{SPACE}writes,%{SPACE}%{NUMBER:osd.wall.syncs:float}(K|M|G)?%{SPACE}syncs,%{SPACE}%{NUMBER:osd.wall.writes_per_sync:float}%{SPACE}writes per sync, written\\:%{SPACE}%{NUMBER:osd.wall.written_gb:float}%{SPACE}(GB|MB|TB)?,%{SPACE}%{NUMBER:osd.written_mb_sec:float}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:log.level}", true),"upsert")
        - set(log.attributes["config.parsed"], "ceph_osd") where log.attributes["osd.stats.level"] != nil
        - set(log.attributes["config.parsed"], "ceph_osd") where log.attributes["osd.wall.type"] != nil

transform/ceph_prysm_sidecar:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "prysm-sidecar"
      statements:
        - merge_maps(log.cache, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["access_key_id"], log.cache["access_key_id"])
        - set(log.attributes["authentication_type"], log.cache["authentication_type"])
        - set(log.attributes["bucket"], log.cache["bucket"])
        - set(log.attributes["bytes_received"], log.cache["bytes_received"])
        - set(log.attributes["bytes_sent"], log.cache["bytes_sent"])
        - set(log.attributes["error_code"], log.cache["error_code"])
        - set(log.attributes["http_status"], log.cache["http_status"])
        - set(log.attributes["object"], log.cache["object"])
        - set(log.attributes["object_size"], log.cache["object_size"])
        - set(log.attributes["operation"], log.cache["operation"])
        - set(log.attributes["referrer"], log.cache["referrer"])
        - set(log.attributes["remote_addr"], log.cache["remote_addr"])
        - set(log.attributes["transaction_id"], log.cache["trans_id"])
        - set(log.attributes["temp_url"], log.cache["temp_url"])
        - set(log.attributes["total_time"], log.cache["total_time"])
        - set(log.attributes["uri"], log.cache["uri"])
        - set(log.attributes["user.id"], log.cache["user"])
        - set(log.attributes["user_agent.name"], log.cache["user_agent"])
        - set(log.attributes["keystone_scope.project.id"], log.cache["keystone_scope"]["project"]["id"])
        - set(log.attributes["keystone_scope.project.name"], log.cache["keystone_scope"]["project"]["name"])
        - set(log.attributes["keystone_scope.project.domain.id"], log.cache["keystone_scope"]["project"]["domain"]["id"])
        - set(log.attributes["keystone_scope.project.domain.name"], log.cache["keystone_scope"]["project"]["domain"]["name"])
        - set(log.attributes["keystone_scope.user.id"], log.cache["keystone_scope"]["user"]["id"])
        - set(log.attributes["keystone_scope.user.name"], log.cache["keystone_scope"]["user"]["name"])
        - set(log.attributes["keystone_scope.user.domain.id"], log.cache["keystone_scope"]["user"]["domain"]["id"])
        - set(log.attributes["keystone_scope.user.domain.name"], log.cache["keystone_scope"]["user"]["domain"]["name"])
        - set(log.attributes["keystone_scope.roles"], log.cache["keystone_scope"]["roles"])
        - set(log.attributes["keystone_scope.application.credential.id"], log.cache["keystone_scope"]["application_credential"]["id"])
        - set(log.attributes["keystone_scope.application_credential.name"], log.cache["keystone_scope"]["application_credential"]["name"])
        - set(log.attributes["keystone_scope.application_credential.restricted"], log.cache["keystone_scope"]["application_credential"]["restricted"])
{{- end }}

{{- define "ceph.pipeline" }}
logs/ceph:
  receivers: [file_log/containerd]
  processors: [k8s_attributes, attributes/cluster, transform/ingress, transform/ceph_rgw, transform/ceph_osd, transform/ceph_prysm_sidecar]
  exporters: [routing]
{{- end }}
