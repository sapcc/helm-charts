{
  "order": 0,
  "template": ".monitoring-es-2-*",
  "settings": {
    "index": {
      "codec": "best_compression",
      "mapper": {
        "dynamic": "false"
      },
      "number_of_shards": "1",
      "number_of_replicas": "0"
    }
  },
  "mappings": {
    "shards": {
      "properties": {
        "state_uuid": {
          "type": "keyword"
        },
        "shard": {
          "properties": {
            "node": {
              "type": "keyword"
            },
            "index": {
              "type": "keyword"
            },
            "relocating_node": {
              "type": "keyword"
            },
            "state": {
              "type": "keyword"
            },
            "shard": {
              "type": "long"
            },
            "primary": {
              "type": "boolean"
            }
          }
        }
      }
    },
    "indices_stats": {
      "properties": {
        "indices_stats": {
          "properties": {
            "_all": {
              "properties": {
                "primaries": {
                  "properties": {
                    "docs": {
                      "properties": {
                        "count": {
                          "type": "long"
                        }
                      }
                    }
                  }
                },
                "total": {
                  "properties": {
                    "docs": {
                      "properties": {
                        "count": {
                          "type": "long"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "index_stats": {
      "properties": {
        "index_stats": {
          "properties": {
            "primaries": {
              "properties": {
                "search": {
                  "properties": {
                    "query_total": {
                      "type": "long"
                    },
                    "query_time_in_millis": {
                      "type": "long"
                    }
                  }
                },
                "query_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "docs": {
                  "properties": {
                    "count": {
                      "type": "long"
                    }
                  }
                },
                "fielddata": {
                  "properties": {
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    }
                  }
                },
                "indexing": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "index_time_in_millis": {
                      "type": "long"
                    },
                    "index_total": {
                      "type": "long"
                    }
                  }
                },
                "refresh": {
                  "properties": {
                    "total_time_in_millis": {
                      "type": "long"
                    }
                  }
                },
                "store": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "size_in_bytes": {
                      "type": "long"
                    }
                  }
                },
                "request_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "merges": {
                  "properties": {
                    "total_size_in_bytes": {
                      "type": "long"
                    }
                  }
                },
                "segments": {
                  "properties": {
                    "version_map_memory_in_bytes": {
                      "type": "long"
                    },
                    "norms_memory_in_bytes": {
                      "type": "long"
                    },
                    "count": {
                      "type": "integer"
                    },
                    "term_vectors_memory_in_bytes": {
                      "type": "long"
                    },
                    "index_writer_memory_in_bytes": {
                      "type": "long"
                    },
                    "memory_in_bytes": {
                      "type": "long"
                    },
                    "terms_memory_in_bytes": {
                      "type": "long"
                    },
                    "doc_values_memory_in_bytes": {
                      "type": "long"
                    },
                    "stored_fields_memory_in_bytes": {
                      "type": "long"
                    },
                    "fixed_bit_set_memory_in_bytes": {
                      "type": "long"
                    }
                  }
                }
              }
            },
            "total": {
              "properties": {
                "search": {
                  "properties": {
                    "query_total": {
                      "type": "long"
                    },
                    "query_time_in_millis": {
                      "type": "long"
                    }
                  }
                },
                "query_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "docs": {
                  "properties": {
                    "count": {
                      "type": "long"
                    }
                  }
                },
                "fielddata": {
                  "properties": {
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    }
                  }
                },
                "indexing": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "index_time_in_millis": {
                      "type": "long"
                    },
                    "index_total": {
                      "type": "long"
                    }
                  }
                },
                "refresh": {
                  "properties": {
                    "total_time_in_millis": {
                      "type": "long"
                    }
                  }
                },
                "store": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "size_in_bytes": {
                      "type": "long"
                    }
                  }
                },
                "request_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "merges": {
                  "properties": {
                    "total_size_in_bytes": {
                      "type": "long"
                    }
                  }
                },
                "segments": {
                  "properties": {
                    "version_map_memory_in_bytes": {
                      "type": "long"
                    },
                    "norms_memory_in_bytes": {
                      "type": "long"
                    },
                    "count": {
                      "type": "integer"
                    },
                    "term_vectors_memory_in_bytes": {
                      "type": "long"
                    },
                    "index_writer_memory_in_bytes": {
                      "type": "long"
                    },
                    "memory_in_bytes": {
                      "type": "long"
                    },
                    "terms_memory_in_bytes": {
                      "type": "long"
                    },
                    "doc_values_memory_in_bytes": {
                      "type": "long"
                    },
                    "stored_fields_memory_in_bytes": {
                      "type": "long"
                    },
                    "fixed_bit_set_memory_in_bytes": {
                      "type": "long"
                    }
                  }
                }
              }
            },
            "index": {
              "type": "keyword"
            }
          }
        }
      }
    },
    "cluster_state": {
      "properties": {
        "cluster_state": {
          "properties": {
            "shards": {
              "type": "object"
            },
            "nodes": {
              "enabled": false
            },
            "master_node": {
              "type": "keyword"
            },
            "state_uuid": {
              "type": "keyword"
            },
            "version": {
              "type": "long"
            },
            "status": {
              "type": "keyword"
            }
          }
        }
      }
    },
    "node": {
      "properties": {
        "node": {
          "properties": {
            "id": {
              "type": "keyword"
            }
          }
        },
        "state_uuid": {
          "type": "keyword"
        }
      }
    },
    "index_recovery": {
      "properties": {
        "index_recovery": {
          "enabled": false
        }
      }
    },
    "node_stats": {
      "properties": {
        "node_stats": {
          "properties": {
            "jvm": {
              "type": "object"
            },
            "indices": {
              "properties": {
                "search": {
                  "properties": {
                    "query_total": {
                      "type": "long"
                    },
                    "query_time_in_millis": {
                      "type": "long"
                    }
                  }
                },
                "query_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "docs": {
                  "properties": {
                    "count": {
                      "type": "long"
                    }
                  }
                },
                "fielddata": {
                  "properties": {
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    }
                  }
                },
                "indexing": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "index_time_in_millis": {
                      "type": "long"
                    },
                    "index_total": {
                      "type": "long"
                    }
                  }
                },
                "request_cache": {
                  "properties": {
                    "miss_count": {
                      "type": "long"
                    },
                    "memory_size_in_bytes": {
                      "type": "long"
                    },
                    "evictions": {
                      "type": "long"
                    },
                    "hit_count": {
                      "type": "long"
                    }
                  }
                },
                "store": {
                  "properties": {
                    "throttle_time_in_millis": {
                      "type": "long"
                    },
                    "size_in_bytes": {
                      "type": "long"
                    }
                  }
                },
                "segments": {
                  "properties": {
                    "version_map_memory_in_bytes": {
                      "type": "long"
                    },
                    "norms_memory_in_bytes": {
                      "type": "long"
                    },
                    "count": {
                      "type": "integer"
                    },
                    "term_vectors_memory_in_bytes": {
                      "type": "long"
                    },
                    "index_writer_memory_in_bytes": {
                      "type": "long"
                    },
                    "memory_in_bytes": {
                      "type": "long"
                    },
                    "terms_memory_in_bytes": {
                      "type": "long"
                    },
                    "doc_values_memory_in_bytes": {
                      "type": "long"
                    },
                    "stored_fields_memory_in_bytes": {
                      "type": "long"
                    },
                    "fixed_bit_set_memory_in_bytes": {
                      "type": "long"
                    }
                  }
                }
              }
            },
            "process": {
              "type": "object"
            },
            "node_master": {
              "type": "boolean"
            },
            "os": {
              "properties": {
                "cpu": {
                  "properties": {
                    "load_average": {
                      "properties": {
                        "5m": {
                          "type": "half_float"
                        },
                        "15m": {
                          "type": "half_float"
                        },
                        "1m": {
                          "type": "half_float"
                        }
                      }
                    }
                  }
                },
                "cgroup": {
                  "properties": {
                    "cpu": {
                      "properties": {
                        "stat": {
                          "properties": {
                            "number_of_elapsed_periods": {
                              "type": "long"
                            },
                            "number_of_times_throttled": {
                              "type": "long"
                            },
                            "time_throttled_nanos": {
                              "type": "long"
                            }
                          }
                        },
                        "control_group": {
                          "type": "keyword"
                        }
                      }
                    },
                    "cpuacct": {
                      "properties": {
                        "control_group": {
                          "type": "keyword"
                        },
                        "usage_nanos": {
                          "type": "long"
                        }
                      }
                    }
                  }
                }
              }
            },
            "thread_pool": {
              "type": "object"
            },
            "mlockall": {
              "type": "boolean"
            },
            "fs": {
              "properties": {
                "io_stats": {
                  "properties": {
                    "total": {
                      "properties": {
                        "write_operations": {
                          "type": "long"
                        },
                        "write_kilobytes": {
                          "type": "long"
                        },
                        "operations": {
                          "type": "long"
                        },
                        "read_operations": {
                          "type": "long"
                        },
                        "read_kilobytes": {
                          "type": "long"
                        }
                      }
                    }
                  }
                },
                "data": {
                  "properties": {
                    "spins": {
                      "type": "boolean"
                    }
                  }
                }
              }
            },
            "node_id": {
              "type": "keyword"
            }
          }
        }
      }
    },
    "cluster_stats": {
      "properties": {
        "cluster_stats": {
          "properties": {
            "indices": {
              "type": "object"
            },
            "nodes": {
              "type": "object"
            }
          }
        }
      }
    },
    "_default_": {
      "_all": {
        "enabled": false
      },
      "date_detection": false,
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
    }
  },
  "aliases": {}
}
