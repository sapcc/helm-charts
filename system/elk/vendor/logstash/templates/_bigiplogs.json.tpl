{
  "order": 0,
  "index_patterns": [
    "bigiplogs-*"
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
      "path": {
        "type": "text"
      },
      "@timestamp": {
        "format": "strict_date_optional_time||epoch_millis",
        "type": "date"
      },
      "syslog_hostname": {
        "type": "keyword"
      },
      "syslog_timestamp": {
        "type": "text"
      },
      "@version": {
        "type": "text"
      },
      "host": {
        "type": "text"
      },
      "syslog_program": {
        "type": "keyword"
      },
      "message": {
        "type": "text"
      },
      "syslog_message": {
        "type": "keyword"
      },
      "syslog_severity": {
        "type": "keyword"
      }
    }
  },
  "aliases": {}
}
