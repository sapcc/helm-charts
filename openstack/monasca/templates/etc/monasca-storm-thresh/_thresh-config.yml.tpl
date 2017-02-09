metricSpoutThreads: 2
metricSpoutTasks: 2
numWorkerProcesses: 2

# TODO: the metric names are too long and impossible to understand

statsdConfig:
  host: localhost
  port: 8125
  debugmetrics: false
  dimensions: !!map
    service : monitoring
    component : apache-storm
  whitelist: !!seq
    - aggregation-bolt.execute-count.filtering-bolt_alarm-creation-stream
    - aggregation-bolt.execute-count.filtering-bolt_default
    - aggregation-bolt.execute-count.system_tick
    - filtering-bolt.execute-count.event-bolt_metric-alarm-events
    - filtering-bolt.execute-count.metrics-spout_default
    - thresholding-bolt.execute-count.aggregation-bolt_default
    - thresholding-bolt.execute-count.event-bolt_alarm-definition-events
    - system.memory_heap.committedBytes
    - system.memory_nonHeap.committedBytes
    - system.newWorkerEvent
    - system.startTimeSecs
    - system.GC_ConcurrentMarkSweep.timeMs
  metricmap: !!map
    acker.emit-count.metrics :
      monasca.thresh.acker.emit-count.metrics
    acker.receive.capacity :
      monasca.thresh.acker.receive.capacity
    acker.receive.population :
      monasca.thresh.acker.receive.population
    acker.receive.read_pos :
      monasca.thresh.acker.receive.read_pos
    acker.receive.write_pos :
      monasca.thresh.acker.receive.write_pos
    acker.sendqueue.capacity :
      monasca.thresh.acker.sendqueue.capacity
    acker.sendqueue.population :
      monasca.thresh.acker.sendqueue.population
    acker.sendqueue.read_pos :
      monasca.thresh.acker.sendqueue.read_pos
    acker.sendqueue.write_pos :
      monasca.thresh.acker.sendqueue.write_pos
    acker.transfer-count.metrics :
      monasca.thresh.acker.transfer-count.metrics
    aggregation-bolt.ack-count.alarm-creation-bolt_alarm-creation-stream :
      monasca.thresh.aggregation-bolt.ack-count.alarm-creation-bolt_alarm-creation-stream
    aggregation-bolt.ack-count.event-bolt_metric-sub-alarm-events :
      monasca.thresh.aggregation-bolt.ack-count.event-bolt_metric-sub-alarm-events
    aggregation-bolt.ack-count.filtering-bolt_default :
      monasca.thresh.aggregation-bolt.ack-count.filtering-bolt_default
    aggregation-bolt.ack-count.system_tick :
      monasca.thresh.aggregation-bolt.ack-count.system_tick
    aggregation-bolt.emit-count.default :
      monasca.thresh.aggregation-bolt.emit-count.default
    aggregation-bolt.emit-count.metrics :
      monasca.thresh.aggregation-bolt.emit-count.metrics
    aggregation-bolt.emit-count.system :
      monasca.thresh.aggregation-bolt.emit-count.system
    aggregation-bolt.execute-count.alarm-creation-bolt_alarm-creation-stream :
      monasca.thresh.aggregation-bolt.execute-count.alarm-creation-bolt_alarm-creation-stream
    aggregation-bolt.execute-count.event-bolt_metric-sub-alarm-events :
      monasca.thresh.aggregation-bolt.execute-count.event-bolt_metric-sub-alarm-events
    aggregation-bolt.execute-count.filtering-bolt_default :
      monasca.thresh.aggregation-bolt.execute-count.filtering-bolt_default
    aggregation-bolt.execute-count.system_tick :
      monasca.thresh.aggregation-bolt.execute-count.system_tick
    aggregation-bolt.execute-latency.alarm-creation-bolt_alarm-creation-stream :
      monasca.thresh.aggregation-bolt.execute-latency.alarm-creation-bolt_alarm-creation-stream
    aggregation-bolt.execute-latency.event-bolt_metric-sub-alarm-events :
      monasca.thresh.aggregation-bolt.execute-latency.event-bolt_metric-sub-alarm-events
    aggregation-bolt.execute-latency.filtering-bolt_default :
      monasca.thresh.aggregation-bolt.execute-latency.filtering-bolt_default
    aggregation-bolt.execute-latency.system_tick :
      monasca.thresh.aggregation-bolt.execute-latency.system_tick
    aggregation-bolt.process-latency.alarm-creation-bolt_alarm-creation-stream :
      monasca.thresh.aggregation-bolt.process-latency.alarm-creation-bolt_alarm-creation-stream
    aggregation-bolt.process-latency.event-bolt_metric-sub-alarm-events :
      monasca.thresh.aggregation-bolt.process-latency.event-bolt_metric-sub-alarm-events
    aggregation-bolt.process-latency.filtering-bolt_default :
      monasca.thresh.aggregation-bolt.process-latency.filtering-bolt_default
    aggregation-bolt.process-latency.system_tick :
      monasca.thresh.aggregation-bolt.process-latency.system_tick
    aggregation-bolt.receive.capacity :
      monasca.thresh.aggregation-bolt.receive.capacity
    aggregation-bolt.receive.population :
      monasca.thresh.aggregation-bolt.receive.population
    aggregation-bolt.receive.read_pos :
      monasca.thresh.aggregation-bolt.receive.read_pos
    aggregation-bolt.receive.write_pos :
      monasca.thresh.aggregation-bolt.receive.write_pos
    aggregation-bolt.sendqueue.capacity :
      monasca.thresh.aggregation-bolt.sendqueue.capacity
    aggregation-bolt.sendqueue.population :
      monasca.thresh.aggregation-bolt.sendqueue.population
    aggregation-bolt.sendqueue.read_pos :
      monasca.thresh.aggregation-bolt.sendqueue.read_pos
    aggregation-bolt.sendqueue.write_pos :
      monasca.thresh.aggregation-bolt.sendqueue.write_pos
    aggregation-bolt.transfer-count.default :
      monasca.thresh.aggregation-bolt.transfer-count.default
    aggregation-bolt.transfer-count.metrics :
      monasca.thresh.aggregation-bolt.transfer-count.metrics
    aggregation-bolt.transfer-count.system :
      monasca.thresh.aggregation-bolt.transfer-count.system
    alarm-creation-bolt.ack-count.event-bolt_alarm-definition-events :
      monasca.thresh.alarm-creation-bolt.ack-count.event-bolt_alarm-definition-events
    alarm-creation-bolt.ack-count.filtering-bolt_newMetricForAlarmDefinitionStream :
      monasca.thresh.alarm-creation-bolt.ack-count.filtering-bolt_newMetricForAlarmDefinitionStream
    alarm-creation-bolt.emit-count.alarm-creation-stream :
      monasca.thresh.alarm-creation-bolt.emit-count.alarm-creation-stream
    alarm-creation-bolt.emit-count.metrics :
      monasca.thresh.alarm-creation-bolt.emit-count.metrics
    alarm-creation-bolt.execute-count.event-bolt_alarm-definition-events :
      monasca.thresh.alarm-creation-bolt.execute-count.event-bolt_alarm-definition-events
    alarm-creation-bolt.execute-count.filtering-bolt_newMetricForAlarmDefinitionStream :
      monasca.thresh.alarm-creation-bolt.execute-count.filtering-bolt_newMetricForAlarmDefinitionStream
    alarm-creation-bolt.execute-latency.event-bolt_alarm-definition-events :
      monasca.thresh.alarm-creation-bolt.execute-latency.event-bolt_alarm-definition-events
    alarm-creation-bolt.execute-latency.filtering-bolt_newMetricForAlarmDefinitionStream :
      monasca.thresh.alarm-creation-bolt.execute-latency.filtering-bolt_newMetricForAlarmDefinitionStream
    alarm-creation-bolt.process-latency.event-bolt_alarm-definition-events :
      monasca.thresh.alarm-creation-bolt.process-latency.event-bolt_alarm-definition-events
    alarm-creation-bolt.process-latency.filtering-bolt_newMetricForAlarmDefinitionStream :
      monasca.thresh.alarm-creation-bolt.process-latency.filtering-bolt_newMetricForAlarmDefinitionStream
    alarm-creation-bolt.receive.capacity :
      monasca.thresh.alarm-creation-bolt.receive.capacity
    alarm-creation-bolt.receive.population :
      monasca.thresh.alarm-creation-bolt.receive.population
    alarm-creation-bolt.receive.read_pos :
      monasca.thresh.alarm-creation-bolt.receive.read_pos
    alarm-creation-bolt.receive.write_pos :
      monasca.thresh.alarm-creation-bolt.receive.write_pos
    alarm-creation-bolt.sendqueue.capacity :
      monasca.thresh.alarm-creation-bolt.sendqueue.capacity
    alarm-creation-bolt.sendqueue.population :
      monasca.thresh.alarm-creation-bolt.sendqueue.population
    alarm-creation-bolt.sendqueue.read_pos :
      monasca.thresh.alarm-creation-bolt.sendqueue.read_pos
    alarm-creation-bolt.sendqueue.write_pos :
      monasca.thresh.alarm-creation-bolt.sendqueue.write_pos
    alarm-creation-bolt.transfer-count.alarm-creation-stream :
      monasca.thresh.alarm-creation-bolt.transfer-count.alarm-creation-stream
    alarm-creation-bolt.transfer-count.metrics :
      monasca.thresh.alarm-creation-bolt.transfer-count.metrics
    event-bolt.emit-count.alarm-definition-events :
      monasca.thresh.event-bolt.emit-count.alarm-definition-events
    event-bolt.emit-count.metrics :
      monasca.thresh.event-bolt.emit-count.metrics
    event-bolt.execute-count.event-spout_default :
      monasca.thresh.event-bolt.execute-count.event-spout_default
    event-bolt.execute-latency.event-spout_default :
      monasca.thresh.event-bolt.execute-latency.event-spout_default
    event-bolt.receive.capacity :
      monasca.thresh.event-bolt.receive.capacity
    event-bolt.receive.population :
      monasca.thresh.event-bolt.receive.population
    event-bolt.receive.read_pos :
      monasca.thresh.event-bolt.receive.read_pos
    event-bolt.receive.write_pos :
      monasca.thresh.event-bolt.receive.write_pos
    event-bolt.sendqueue.capacity :
      monasca.thresh.event-bolt.sendqueue.capacity
    event-bolt.sendqueue.population :
      monasca.thresh.event-bolt.sendqueue.population
    event-bolt.sendqueue.read_pos :
      monasca.thresh.event-bolt.sendqueue.read_pos
    event-bolt.sendqueue.write_pos :
      monasca.thresh.event-bolt.sendqueue.write_pos
    event-bolt.transfer-count.alarm-definition-events :
      monasca.thresh.event-bolt.transfer-count.alarm-definition-events
    event-bolt.transfer-count.metrics :
      monasca.thresh.event-bolt.transfer-count.metrics
    event-spout.emit-count.default :
      monasca.thresh.event-spout.emit-count.default
    event-spout.emit-count.metrics :
      monasca.thresh.event-spout.emit-count.metrics
    event-spout.receive.capacity :
      monasca.thresh.event-spout.receive.capacity
    event-spout.receive.population :
      monasca.thresh.event-spout.receive.population
    event-spout.receive.read_pos :
      monasca.thresh.event-spout.receive.read_pos
    event-spout.receive.write_pos :
      monasca.thresh.event-spout.receive.write_pos
    event-spout.sendqueue.capacity :
      monasca.thresh.event-spout.sendqueue.capacity
    event-spout.sendqueue.population :
      monasca.thresh.event-spout.sendqueue.population
    event-spout.sendqueue.read_pos :
      monasca.thresh.event-spout.sendqueue.read_pos
    event-spout.sendqueue.write_pos :
      monasca.thresh.event-spout.sendqueue.write_pos
    event-spout.transfer-count.default :
      monasca.thresh.event-spout.transfer-count.default
    event-spout.transfer-count.metrics :
      monasca.thresh.event-spout.transfer-count.metrics
    filtering-bolt.ack-count.event-bolt_alarm-definition-events :
      monasca.thresh.filtering-bolt.ack-count.event-bolt_alarm-definition-events
    filtering-bolt.ack-count.metrics-spout_default :
      monasca.thresh.filtering-bolt.ack-count.metrics-spout_default
    filtering-bolt.emit-count.default :
      monasca.thresh.filtering-bolt.emit-count.default
    filtering-bolt.emit-count.metrics :
      monasca.thresh.filtering-bolt.emit-count.metrics
    filtering-bolt.emit-count.newMetricForAlarmDefinitionStream :
      monasca.thresh.filtering-bolt.emit-count.newMetricForAlarmDefinitionStream
    filtering-bolt.execute-count.event-bolt_alarm-definition-events :
      monasca.thresh.filtering-bolt.execute-count.event-bolt_alarm-definition-events
    filtering-bolt.execute-count.metrics-spout_default :
      monasca.thresh.filtering-bolt.execute-count.metrics-spout_default
    filtering-bolt.execute-latency.event-bolt_alarm-definition-events :
      monasca.thresh.filtering-bolt.execute-latency.event-bolt_alarm-definition-events
    filtering-bolt.execute-latency.metrics-spout_default :
      monasca.thresh.filtering-bolt.execute-latency.metrics-spout_default
    filtering-bolt.process-latency.event-bolt_alarm-definition-events :
      monasca.thresh.filtering-bolt.process-latency.event-bolt_alarm-definition-events
    filtering-bolt.process-latency.metrics-spout_default :
      monasca.thresh.filtering-bolt.process-latency.metrics-spout_default
    filtering-bolt.receive.capacity :
      monasca.thresh.filtering-bolt.receive.capacity
    filtering-bolt.receive.population :
      monasca.thresh.filtering-bolt.receive.population
    filtering-bolt.receive.read_pos :
      monasca.thresh.filtering-bolt.receive.read_pos
    filtering-bolt.receive.write_pos :
      monasca.thresh.filtering-bolt.receive.write_pos
    filtering-bolt.sendqueue.capacity :
      monasca.thresh.filtering-bolt.sendqueue.capacity
    filtering-bolt.sendqueue.population :
      monasca.thresh.filtering-bolt.sendqueue.population
    filtering-bolt.sendqueue.read_pos :
      monasca.thresh.filtering-bolt.sendqueue.read_pos
    filtering-bolt.sendqueue.write_pos :
      monasca.thresh.filtering-bolt.sendqueue.write_pos
    filtering-bolt.transfer-count.default :
      monasca.thresh.filtering-bolt.transfer-count.default
    filtering-bolt.transfer-count.metrics :
      monasca.thresh.filtering-bolt.transfer-count.metrics
    filtering-bolt.transfer-count.newMetricForAlarmDefinitionStream :
      monasca.thresh.filtering-bolt.transfer-count.newMetricForAlarmDefinitionStream
    metrics-spout.emit-count.default :
      monasca.thresh.metrics-spout.emit-count.default
    metrics-spout.emit-count.metrics :
      monasca.thresh.metrics-spout.emit-count.metrics
    metrics-spout.receive.capacity :
      monasca.thresh.metrics-spout.receive.capacity
    metrics-spout.receive.population :
      monasca.thresh.metrics-spout.receive.population
    metrics-spout.receive.read_pos :
      monasca.thresh.metrics-spout.receive.read_pos
    metrics-spout.receive.write_pos :
      monasca.thresh.metrics-spout.receive.write_pos
    metrics-spout.sendqueue.capacity :
      monasca.thresh.metrics-spout.sendqueue.capacity
    metrics-spout.sendqueue.population :
      monasca.thresh.metrics-spout.sendqueue.population
    metrics-spout.sendqueue.read_pos :
      monasca.thresh.metrics-spout.sendqueue.read_pos
    metrics-spout.sendqueue.write_pos :
      monasca.thresh.metrics-spout.sendqueue.write_pos
    metrics-spout.transfer-count.default :
      monasca.thresh.metrics-spout.transfer-count.default
    metrics-spout.transfer-count.metrics :
      monasca.thresh.metrics-spout.transfer-count.metrics
    system.emit-count.metrics :
      monasca.thresh.system.emit-count.metrics
    system.GC_ConcurrentMarkSweep.count :
      monasca.thresh.system.GC_ConcurrentMarkSweep.count
    system.GC_ConcurrentMarkSweep.timeMs :
      monasca.thresh.system.GC_ConcurrentMarkSweep.timeMs
    system.GC_ParNew.count :
      monasca.thresh.system.GC_ParNew.count
    system.GC_ParNew.timeMs :
      monasca.thresh.system.GC_ParNew.timeMs
    system.memory_heap.committedBytes :
      monasca.thresh.system.memory_heap.committedBytes
    system.memory_heap.initBytes :
      monasca.thresh.system.memory_heap.initBytes
    system.memory_heap.maxBytes :
      monasca.thresh.system.memory_heap.maxBytes
    system.memory_heap.unusedBytes :
      monasca.thresh.system.memory_heap.unusedBytes
    system.memory_heap.usedBytes :
      monasca.thresh.system.memory_heap.usedBytes
    system.memory_heap.virtualFreeBytes :
      monasca.thresh.system.memory_heap.virtualFreeBytes
    system.memory_nonHeap.committedBytes :
      monasca.thresh.system.memory_nonHeap.committedBytes
    system.memory_nonHeap.initBytes :
      monasca.thresh.system.memory_nonHeap.initBytes
    system.memory_nonHeap.maxBytes :
      monasca.thresh.system.memory_nonHeap.maxBytes
    system.memory_nonHeap.unusedBytes :
      monasca.thresh.system.memory_nonHeap.unusedBytes
    system.memory_nonHeap.usedBytes :
      monasca.thresh.system.memory_nonHeap.usedBytes
    system.memory_nonHeap.virtualFreeBytes :
      monasca.thresh.system.memory_nonHeap.virtualFreeBytes
    system.newWorkerEvent :
      monasca.thresh.system.newWorkerEvent
    system.receive.capacity :
      monasca.thresh.system.receive.capacity
    system.receive.population :
      monasca.thresh.system.receive.population
    system.receive.read_pos :
      monasca.thresh.system.receive.read_pos
    system.receive.write_pos :
      monasca.thresh.system.receive.write_pos
    system.sendqueue.capacity :
      monasca.thresh.system.sendqueue.capacity
    system.sendqueue.population :
      monasca.thresh.system.sendqueue.population
    system.sendqueue.read_pos :
      monasca.thresh.system.sendqueue.read_pos
    system.sendqueue.write_pos :
      monasca.thresh.system.sendqueue.write_pos
    system.startTimeSecs :
      monasca.thresh.system.startTimeSecs
    system.transfer.capacity :
      monasca.thresh.system.transfer.capacity
    system.transfer-count.metrics :
      monasca.thresh.system.transfer-count.metrics
    system.transfer.population :
      monasca.thresh.system.transfer.population
    system.transfer.read_pos :
      monasca.thresh.system.transfer.read_pos
    system.transfer.write_pos :
      monasca.thresh.system.transfer.write_pos
    system.uptimeSecs :
      monasca.thresh.system.uptimeSecs
    thresholding-bolt.ack-count.aggregation-bolt_default :
      monasca.thresh.thresholding-bolt.ack-count.aggregation-bolt_default
    thresholding-bolt.ack-count.event-bolt_alarm-definition-events :
      monasca.thresh.thresholding-bolt.ack-count.event-bolt_alarm-definition-events
    thresholding-bolt.ack-count.event-bolt_metric-sub-alarm-events :
      monasca.thresh.thresholding-bolt.ack-count.event-bolt_metric-sub-alarm-events
    thresholding-bolt.emit-count.metrics :
      monasca.thresh.thresholding-bolt.emit-count.metrics
    thresholding-bolt.execute-count.aggregation-bolt_default :
      monasca.thresh.thresholding-bolt.execute-count.aggregation-bolt_default
    thresholding-bolt.execute-count.event-bolt_alarm-definition-events :
      monasca.thresh.thresholding-bolt.execute-count.event-bolt_alarm-definition-events
    thresholding-bolt.execute-count.event-bolt_metric-sub-alarm-events :
      monasca.thresh.thresholding-bolt.execute-count.event-bolt_metric-sub-alarm-events
    thresholding-bolt.execute-latency.aggregation-bolt_default :
      monasca.thresh.thresholding-bolt.execute-latency.aggregation-bolt_default
    thresholding-bolt.execute-latency.event-bolt_alarm-definition-events :
      monasca.thresh.thresholding-bolt.execute-latency.event-bolt_alarm-definition-events
    thresholding-bolt.execute-latency.event-bolt_metric-sub-alarm-events :
      monasca.thresh.thresholding-bolt.execute-latency.event-bolt_metric-sub-alarm-events
    thresholding-bolt.process-latency.aggregation-bolt_default :
      monasca.thresh.thresholding-bolt.process-latency.aggregation-bolt_default
    thresholding-bolt.process-latency.event-bolt_alarm-definition-events :
      monasca.thresh.thresholding-bolt.process-latency.event-bolt_alarm-definition-events
    thresholding-bolt.process-latency.event-bolt_metric-sub-alarm-events :
      monasca.thresh.thresholding-bolt.process-latency.event-bolt_metric-sub-alarm-events
    thresholding-bolt.receive.capacity :
      monasca.thresh.thresholding-bolt.receive.capacity
    thresholding-bolt.receive.population :
      monasca.thresh.thresholding-bolt.receive.population
    thresholding-bolt.receive.read_pos :
      monasca.thresh.thresholding-bolt.receive.read_pos
    thresholding-bolt.receive.write_pos :
      monasca.thresh.thresholding-bolt.receive.write_pos
    thresholding-bolt.sendqueue.capacity :
      monasca.thresh.thresholding-bolt.sendqueue.capacity
    thresholding-bolt.sendqueue.population :
      monasca.thresh.thresholding-bolt.sendqueue.population
    thresholding-bolt.sendqueue.read_pos :
      monasca.thresh.thresholding-bolt.sendqueue.read_pos
    thresholding-bolt.sendqueue.write_pos :
      monasca.thresh.thresholding-bolt.sendqueue.write_pos
    thresholding-bolt.transfer-count.metrics :
      monasca.thresh.thresholding-bolt.transfer-count.metrics

metricSpoutConfig:

  #Kafka settings.
  kafkaConsumerConfiguration:
  # See http://kafka.apache.org/documentation.html#api for semantics and defaults.
    topic: metrics
    numThreads: 4
    groupId: thresh
    zookeeperConnect: zk:{{.Values.monasca_zookeeper_port_internal}}
    consumerId: KAFKA_CONSUMER_ID
    socketTimeoutMs: 30000
    socketReceiveBufferBytes : 65536
    fetchMessageMaxBytes: 1048576
    autoCommitEnable: true
    autoCommitIntervalMs: 60000
    queuedMaxMessageChunks: 10
    rebalanceMaxRetries: 4
    fetchMinBytes:  1
    fetchWaitMaxMs:  100
    rebalanceBackoffMs: 2000
    refreshLeaderBackoffMs: 200
    autoOffsetReset: largest
    consumerTimeoutMs:  -1
    clientId: monasca-thresh 
    zookeeperSessionTimeoutMs : 60000
    zookeeperConnectionTimeoutMs : 60000
    zookeeperSyncTimeMs: 2000


eventSpoutConfig:
  #Kafka settings.
  kafkaConsumerConfiguration:
  # See http://kafka.apache.org/documentation.html#api for semantics and defaults.
    topic: events
    numThreads: 4
    groupId: thresh
    zookeeperConnect: zk:{{.Values.monasca_zookeeper_port_internal}}
    consumerId: KAFKA_CONSUMER_ID
    socketTimeoutMs: 30000
    socketReceiveBufferBytes : 65536
    fetchMessageMaxBytes: 1048576
    autoCommitEnable: true
    autoCommitIntervalMs: 60000
    queuedMaxMessageChunks: 10
    rebalanceMaxRetries: 4
    fetchMinBytes:  1
    fetchWaitMaxMs:  100
    rebalanceBackoffMs: 2000
    refreshLeaderBackoffMs: 200
    autoOffsetReset: largest
    consumerTimeoutMs:  -1
    clientId: monasca-thresh
    zookeeperSessionTimeoutMs : 60000
    zookeeperConnectionTimeoutMs : 60000
    zookeeperSyncTimeMs: 2000


kafkaProducerConfig:
  # See http://kafka.apache.org/documentation.html#api for semantics and defaults.
  topic: alarm-state-transitions
  metadataBrokerList: kafka:{{.Values.monasca_kafka_port_internal}}
  serializerClass: kafka.serializer.StringEncoder
  partitionerClass:
  requestRequiredAcks: 1
  requestTimeoutMs: 10000
  producerType: sync
  keySerializerClass:
  compressionCodec: none
  compressedTopics:
  messageSendMaxRetries: 3
  retryBackoffMs: 100
  topicMetadataRefreshIntervalMs: 600000
  queueBufferingMaxMs: 5000
  queueBufferingMaxMessages: 10000
  queueEnqueueTimeoutMs: -1
  batchNumMessages: 200
  sendBufferBytes: 102400
  clientId: monasca-thresh
sporadicMetricNamespaces:
  - foo

database:
  driverClass: com.mysql.jdbc.Driver
  url: jdbc:mysql://{{.Values.monasca_mysql_endpoint_host_internal}}:{{.Values.monasca_mysql_port_internal}}/mon
  user: thresh
  password: {{.Values.monasca_mysql_thresh_password}}
  properties:
      ssl: false
  # the maximum amount of time to wait on an empty pool before throwing an exception
  maxWaitForConnection: 5s

  # the SQL query to run when validating a connection's liveness
  validationQuery: "/* MyService Health Check */ SELECT 1"

  # the minimum number of connections to keep open
  minSize: 8

  # the maximum number of connections to keep open


  maxSize: 41
