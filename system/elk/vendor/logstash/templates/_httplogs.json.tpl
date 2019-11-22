{
  "order": 0,
  "index_patterns": [
    "httplogs-*"
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
      "agent": {
        "type": "text"
      },
      "bytes_received": {
        "type": "integer"
      },
      "client_ip": {
        "type": "ip"
      },
      "client_port": {
        "type": "keyword"
      },
      "host": {
        "type": "keyword"
      },
      "http_status": {
        "type": "keyword"
      },
      "http_version": {
        "type": "text"
      },
      "message": {
        "type": "text"
      },
      "path": {
        "type": "text"
      },
      "referrer": {
        "type": "text"
      },
      "response_time": {
        "type": "integer"
      },
      "server_ip": {
        "type": "ip"
      },
      "server_port": {
        "type": "keyword"
      },
      "syslog_hostname": {
        "type": "keyword"
      },
      "syslog_timestamp": {
        "type": "keyword"
      },
      "uri_path": {
        "type": "text"
      },
      "virtual_port": {
        "type": "keyword"
      },
      "virtual_ip": {
        "type": "ip"
      }
    }
  },
  "aliases": {}
}
