status = warn

# log action execution errors for easier debugging
logger.action.name = org.elasticsearch.action
logger.action.level = warn

appender.console.type = Console
appender.console.name = console
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker%m%n

appender.rolling.type = RollingFile
appender.rolling.name = rolling
appender.rolling.fileName = ${sys:es.logs}.log
appender.rolling.layout.type = PatternLayout
appender.rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker.-10000m%n
appender.rolling.filePattern = ${sys:es.logs}-%d{yyyy-MM-dd}.log
appender.rolling.policies.type = Policies
appender.rolling.policies.time.type = TimeBasedTriggeringPolicy
appender.rolling.policies.time.interval = 1
appender.rolling.policies.time.modulate = true

rootLogger.level = warn
rootLogger.appenderRef.console.ref = console
#rootLogger.appenderRef.rolling.ref = rolling

appender.deprecation_rolling.type = RollingFile
appender.deprecation_rolling.name = deprecation_rolling
appender.deprecation_rolling.fileName = ${sys:es.logs}_deprecation.log
appender.deprecation_rolling.layout.type = PatternLayout
appender.deprecation_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] [%node_name]%marker.-10000m%n
appender.deprecation_rolling.filePattern = ${sys:es.logs}_deprecation-%i.log.gz
appender.deprecation_rolling.policies.type = Policies
appender.deprecation_rolling.policies.size.type = SizeBasedTriggeringPolicy
appender.deprecation_rolling.policies.size.size = 1GB
appender.deprecation_rolling.strategy.type = DefaultRolloverStrategy
appender.deprecation_rolling.strategy.max = 4

logger.deprecation.name = org.elasticsearch.deprecation
#logger.deprecation.level = warn
logger.deprecation.level = off
logger.deprecation.appenderRef.console.ref = console
#logger.deprecation.appenderRef.deprecation_rolling.ref = console
logger.deprecation.additivity = false

appender.index_search_slowlog_rolling.type = RollingFile
appender.index_search_slowlog_rolling.name = index_search_slowlog_rolling
appender.index_search_slowlog_rolling.fileName = ${sys:es.logs}_index_search_slowlog.log
appender.index_search_slowlog_rolling.layout.type = PatternLayout
appender.index_search_slowlog_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] [%node_name]%marker.-10000m%n
appender.index_search_slowlog_rolling.filePattern = ${sys:es.logs}_index_search_slowlog-%d{yyyy-MM-dd}.log
appender.index_search_slowlog_rolling.policies.type = Policies
appender.index_search_slowlog_rolling.policies.time.type = TimeBasedTriggeringPolicy
appender.index_search_slowlog_rolling.policies.time.interval = 1
appender.index_search_slowlog_rolling.policies.time.modulate = true

logger.index_search_slowlog_rolling.name = index.search.slowlog
logger.index_search_slowlog_rolling.level = trace
logger.index_search_slowlog_rolling.appenderRef.console.ref = console
#logger.index_search_slowlog_rolling.appenderRef.index_search_slowlog_rolling.ref = console
logger.index_search_slowlog_rolling.additivity = false

appender.index_indexing_slowlog_rolling.type = RollingFile
appender.index_indexing_slowlog_rolling.name = index_indexing_slowlog_rolling
appender.index_indexing_slowlog_rolling.fileName = ${sys:es.logs}_index_indexing_slowlog.log
appender.index_indexing_slowlog_rolling.layout.type = PatternLayout
appender.index_indexing_slowlog_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] [%node_name]%marker.-10000m%n
appender.index_indexing_slowlog_rolling.filePattern = ${sys:es.logs}_index_indexing_slowlog-%d{yyyy-MM-dd}.log
appender.index_indexing_slowlog_rolling.policies.type = Policies
appender.index_indexing_slowlog_rolling.policies.time.type = TimeBasedTriggeringPolicy
appender.index_indexing_slowlog_rolling.policies.time.interval = 1
appender.index_indexing_slowlog_rolling.policies.time.modulate = true

logger.index_indexing_slowlog.name = index.indexing.slowlog.index
logger.index_indexing_slowlog.level = warn
logger.index_indexing_slowlog.appenderRef.console.ref = console
#logger.index_indexing_slowlog.appenderRef.index_indexing_slowlog_rolling.ref = console
logger.index_indexing_slowlog.additivity = false

#Plugin readonly rest logging file definition
appender.access_log_rolling.type = RollingFile
appender.access_log_rolling.name = access_log_rolling
appender.access_log_rolling.fileName = ${sys:es.logs}_access.log
appender.access_log_rolling.layout.pattern = [%d{ISO8601}][%-5p][%-25c] [%node_name]%marker.-10000m%n
appender.access_log_rolling.layout.type = PatternLayout
appender.access_log_rolling.filePattern = ${sys:es.logs}_access-%d{yyyy-MM-dd}.log
appender.access_log_rolling.policies.type = Policies
appender.access_log_rolling.policies.time.type = TimeBasedTriggeringPolicy
appender.access_log_rolling.policies.time.interval = 1
appender.access_log_rolling.policies.time.modulate = true

logger.access_log_rolling.name = org.elasticsearch.plugin.readonlyrest.acl
logger.access_log_rolling.level = warn
logger.access_log_rolling.appenderRef.console.ref = console
logger.access_log_rolling.additivity = false
