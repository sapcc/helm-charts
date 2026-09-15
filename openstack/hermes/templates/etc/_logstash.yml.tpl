pipeline.ecs_compatibility: disabled
pipeline.workers: 1
pipeline.batch.size: 250
# Pipeline order is not guaranteed regardless, saves processing power
pipeline.ordered: false
config.reload.automatic: true
config.reload.interval: 60s
log.level: info
log.format: json

api.enabled: true
api.http.host: 0.0.0.0
api.http.port: 9600
