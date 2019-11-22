{
  "order": 0,
  "index_patterns": [
    "ddoslogs-*"
  ],
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "3",
      "number_of_replicas": "1"
    }
  },
  "mappings": {
    "properties": {
      "@timestamp": {
        "format": "strict_date_optional_time||epoch_millis",
        "type": "date"
      },
      "@version": {
        "type": "text"
      },
      "action": {
        "type": "text"
      },
      "attack_time": {
        "type": "text"
      },
      "dest_ip": {
        "type": "ip"
      },
      "dest_port": {
        "type": "keyword"
      },
      "dos_attack_event": {
        "type": "text"
      },
      "dos_attack_id": {
        "type": "text"
      },
      "dos_attack_name": {
        "type": "keyword"
      },
      "f5_hostname": {
        "type": "keyword"
      },
      "host": {
        "type": "keyword"
      },
      "message": {
        "type": "text"
      },
      "mgmt_ip": {
        "type": "ip"
      },
      "context": {
        "type": "text"
      },
      "packets_dropped": {
        "type": "integer"
      },
      "packets_received": {
        "type": "integer"
      },
      "partition_name": {
        "type": "keyword"
      },
      "path": {
        "type": "text"
      },
      "route_domain": {
        "type": "keyword"
      },
      "severity": {
        "type": "integer"
      },
      "source_ip": {
        "type": "ip"
      },
      "source_port": {
        "type": "keyword"
      },
      "syslog_hostname": {
        "type": "keyword"
      },
      "syslog_timestamp": {
        "type": "text"
      }
    }
  },
  "aliases": {}
}
