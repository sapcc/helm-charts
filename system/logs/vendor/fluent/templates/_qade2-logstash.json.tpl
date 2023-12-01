{
  "order": 0,
  "template": "qade2-logstash-*",
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "{{ .Values.logstash_shards }}",
      "number_of_replicas": "1",
      "knn": true,
      "default_pipeline": "log-all-MiniLM-L6-v2"
    }
  },
  "mappings": {
    "properties": {
      "id": {
        "type": "text"
      },
      "log_embedding": {
        "type": "knn_vector",
        "dimension": 384,
        "method": {
          "engine": "lucene",
          "space_type": "l2",
          "name": "hnsw",
          "parameters": {}
        }
      },
      "log": {
        "type": "text"
      }
    }
  },
  "aliases": {}
}
