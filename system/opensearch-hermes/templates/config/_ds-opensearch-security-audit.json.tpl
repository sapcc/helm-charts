{
  "index_patterns": [
    "opensearch-security-audit"
  ],
  "data_stream": {},
  "template": {
    "settings": {
      "index.number_of_shards": 1,
      "index.number_of_replicas": 1,
      "index.refresh_interval": "60s",
      "index.mapping.total_fields.limit": 2000,
      "index.codec": "best_compression"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "audit_category": {
          "type": "keyword"
        },
        "audit_cluster_name": {
          "type": "keyword"
        },
        "audit_format_version": {
          "type": "short"
        },
        "audit_node_host_address": {
          "type": "ip"
        },
        "audit_node_host_name": {
          "type": "keyword"
        },
        "audit_node_id": {
          "type": "keyword"
        },
        "audit_node_name": {
          "type": "keyword"
        },
        "audit_request_body": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 2048
            }
          }
        },
        "audit_request_effective_user": {
          "type": "keyword"
        },
        "audit_request_effective_user_is_admin": {
          "type": "boolean"
        },
        "audit_request_initiating_user": {
          "type": "keyword"
        },
        "audit_request_layer": {
          "type": "keyword"
        },
        "audit_request_origin": {
          "type": "keyword"
        },
        "audit_request_privilege": {
          "type": "keyword"
        },
        "audit_request_remote_address": {
          "type": "ip"
        },
        "audit_rest_request_headers": {
          "type": "object",
          "enabled": false
        },
        "audit_rest_request_method": {
          "type": "keyword"
        },
        "audit_rest_request_params": {
          "type": "object",
          "enabled": false
        },
        "audit_rest_request_path": {
          "type": "keyword",
          "fields": {
            "text": {
              "type": "text"
            }
          }
        },
        "audit_transport_headers": {
          "type": "object",
          "enabled": false
        },
        "audit_transport_request_type": {
          "type": "keyword"
        },
        "audit_trace_doc_id": {
          "type": "keyword"
        },
        "audit_trace_indices": {
          "type": "keyword"
        },
        "audit_trace_resolved_indices": {
          "type": "keyword"
        },
        "audit_trace_shard_id": {
          "type": "integer"
        },
        "audit_trace_task_id": {
          "type": "keyword"
        },
        "audit_trace_task_parent_id": {
          "type": "keyword"
        }
      }
    }
  },
  "data_stream_field_meta": {
    "timestamp_field": {
      "name": "@timestamp"
    }
  },
  "priority": 200,
  "_meta": {
    "description": "OpenSearch security plugin audit log datastream — distinct from the Hermes CADF cloud-audit datastream"
  }
}
