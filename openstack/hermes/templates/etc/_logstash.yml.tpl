pipeline.ecs_compatibility: disabled
pipeline.workers: 1
pipeline.batch.size: 250
# Pipeline order is not guaranteed regardless, saves processing power
pipeline.ordered: false
config.reload.automatic: true
config.reload.interval: 60s
http.host: 0.0.0.0
log.level: warn
log.format: json
