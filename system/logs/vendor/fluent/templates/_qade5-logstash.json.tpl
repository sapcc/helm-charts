{
  "order": 0,
  "template": "qade5-logstash-*",
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "{{ .Values.logstash_shards }}",
      "number_of_replicas": "1"
    }
  },
  "mappings": {
    "properties": {
      "request_time": {
        "type": "float"
      },
      "uri_req_duration": {
        "type": "float"
      },
      "response_time": {
        "type": "float"
      },
      "request_start_time": {
        "type": "float"
      },
      "request_end_time": {
        "type": "float"
      },
      "upstream_response_time": {
        "type": "float"
      },
      "bytes_recvd": {
        "type": "integer"
      },
      "bytes_sent": {
        "type": "integer"
      },
      "content_length": {
        "type": "integer"
      },
      "upstream_response_length": {
        "type": "integer"
      }
    }
  },
  "aliases": {}
}
