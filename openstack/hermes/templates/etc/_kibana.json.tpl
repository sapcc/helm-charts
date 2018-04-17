{
  "order": 0,
  "template": ".kibana",
  "settings": {
    "index": {
      "number_of_shards": "1",
      "codec": "best_compression",
      "number_of_replicas": "0"
    }
  },
  "mappings": {
    "_default_": {
      "_all": {
        "enabled": false
      },
      "properties": {
        "cluster_uuid": {
          "type": "keyword"
        },
        "source_node": {
          "properties": {
            "transport_address": {
              "type": "keyword"
            },
            "ip": {
              "type": "keyword"
            },
            "host": {
              "type": "keyword"
            },
            "name": {
              "type": "keyword"
            },
            "attributes": {
              "dynamic": true,
              "properties": {
                "data": {
                  "type": "boolean"
                },
                "client": {
                  "type": "boolean"
                },
                "master": {
                  "type": "boolean"
                }
              }
            },
            "uuid": {
              "type": "keyword"
            }
          }
        },
        "timestamp": {
          "format": "date_time",
          "type": "date"
        }
      }
    },
    "kibana_stats": {
      "properties": {
        "kibana_stats": {
          "properties": {
            "process": {
              "properties": {
                "memory": {
                  "properties": {
                    "resident_set_size_in_bytes": {
                      "type": "float"
                    },
                    "heap": {
                      "properties": {
                        "used_in_bytes": {
                          "type": "float"
                        },
                        "total_in_bytes": {
                          "type": "float"
                        },
                        "size_limit": {
                          "type": "float"
                        }
                      }
                    }
                  }
                },
                "event_loop_delay": {
                  "type": "float"
                },
                "uptime_in_millis": {
                  "type": "long"
                }
              }
            },
            "os": {
              "properties": {
                "memory": {
                  "properties": {
                    "used_in_bytes": {
                      "type": "float"
                    },
                    "total_in_bytes": {
                      "type": "float"
                    },
                    "free_in_bytes": {
                      "type": "float"
                    }
                  }
                },
                "load": {
                  "properties": {
                    "5m": {
                      "type": "float"
                    },
                    "15m": {
                      "type": "float"
                    },
                    "1m": {
                      "type": "float"
                    }
                  }
                },
                "uptime_in_millis": {
                  "type": "long"
                }
              }
            },
            "response_times": {
              "properties": {
                "average": {
                  "type": "float"
                },
                "max": {
                  "type": "float"
                }
              }
            },
            "sockets": {
              "properties": {
                "http": {
                  "properties": {
                    "total": {
                      "type": "long"
                    }
                  }
                },
                "https": {
                  "properties": {
                    "total": {
                      "type": "long"
                    }
                  }
                }
              }
            },
            "requests": {
              "properties": {
                "total": {
                  "type": "long"
                },
                "status_codes": {
                  "type": "object"
                },
                "disconnects": {
                  "type": "long"
                }
              }
            },
            "kibana": {
              "properties": {
                "transport_address": {
                  "type": "keyword"
                },
                "name": {
                  "type": "keyword"
                },
                "host": {
                  "type": "keyword"
                },
                "statuses": {
                  "properties": {
                    "name": {
                      "type": "keyword"
                    },
                    "state": {
                      "type": "keyword"
                    }
                  }
                },
                "uuid": {
                  "type": "keyword"
                },
                "version": {
                  "type": "keyword"
                },
                "snapshot": {
                  "type": "boolean"
                },
                "status": {
                  "type": "keyword"
                }
              }
            },
            "concurrent_connections": {
              "type": "long"
            },
            "timestamp": {
              "type": "date"
            }
          }
        }
      }
    }
  },
  "aliases": {}
}
