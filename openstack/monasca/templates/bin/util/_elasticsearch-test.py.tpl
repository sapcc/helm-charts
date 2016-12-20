{{- define "util_elasticsearch_test_py_tpl" -}}
#!/usr/bin/env python
from elasticsearch import Elasticsearch, RequestsHttpConnection, NotFoundError, ConnectionError
from elasticsearch_dsl import Search
from datetime import datetime
from pytz import timezone
import time
import os
import sys
#from datadog import initialize, statsd

es = Elasticsearch(
['{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}'],
 connection_class=RequestsHttpConnection,
http_auth=('{{.Values.monasca_elasticsearch_admin_user}}', '{{.Values.monasca_elasticsearch_admin_password}}'),
use_ssl=False)

#initialize(statsd_host='localhost', statsd_port=9125)

fmt = "%Y-%m-%d %H:%M:%S %Z%z"
now_utc = datetime.utcnow()
now_cet = datetime.now(timezone('Europe/Berlin'))
index_date = now_utc.strftime('%Y.%m.%d')
check_rs = 'Monitoring check at: %s' % now_cet.strftime(fmt)
print str(check_rs)

doc = {
'@timestamp': now_utc,
'log': check_rs,
'stream': 'monitoring',
'time': now_utc,
'tag': 'self-monitoring',
'tests': 'canary',
'host': 'canarytester'
}

def storeMetric():
  try:
    es.index(index='logstash-%s' % index_date, doc_type='log', body=doc)
  except ConnectionError as ce:
     print ("Elasticsearch host not found while sending logs entry to elasticsearch service: 404")
     print(ce)
     f = open("/checks/status/monasca_elasticsearch_test","w")
     f.write("1")
     f.close()
#     statsd.gauge('elasticsearch.monitoring.status', 0, tags=["method:put, component:elasticsearch"])
     sys.exit(0)
  except Exception as e:
     print("Elasticsearch error while sending logs entry")
     print(e)
     f = open("/checks/status/monasca_elasticsearch_test","w")
     f.write("1")
     f.close()
#     statsd.gauge('elasticsearch.monitoring.status', 0, tags=["method:put, component:elasticsearch"])
     sys.exit(0)
  else:
     f = open("/checks/status/monasca_elasticsearch_test","w")
     f.write("0")
     f.close()
#     statsd.gauge('elasticsearch.monitoring.status', 1, tags=["method:put, component:elasticsearch"])



def searchLoop():
    abort_after = 55
    start = time.time()
    i = 0
    while True:
      delta = time.time() - start
      im = i * 1000
      s = Search(using=es, index='logstash-*', doc_type='log')
      s = s.query("match_phrase", log=str(check_rs))

      try:
       response = s.execute()
      except NotFoundError as nf:
       print ("Elasticsearch host not found while searching for log entry: 404")
       print(nf)
       f = open("/checks/status/monasca_elasticsearch_test","w")
       f.write("1")
       f.close()
#       statsd.gauge('elasticsearch.monitoring.status', 0, tags=["method:get, component:elasticsearch"])
       sys.exit(0)
      except Exception as e:
       print("Elasticsearch error while searching for log entry")
       print(e)
       f = open("/checks/status/monasca_elasticsearch_test","w")
       f.write("1")
       f.close()
#       statsd.gauge('elasticsearch.monitoring.status', 0, tags=["method:get, component:elasticsearch"])
       sys.exit(0)

      if response.success() == True and response.hits.total == 1:
#        print('%d hit found.' % response.hits.total)
#        print('reponse time: %sms' % response.took)
         f = open("/checks/status/monasca_elasticsearch_test","w")
         f.write("0")
         f.close()
#        statsd.gauge('elasticsearch.monitoring.status', 1, tags=["method:get, component:elasticsearch"])
#        statsd.gauge('elasticsearch.monitoring.time', response.took, tags=["method:get, component:elasticsearch"])
#        statsd.gauge('elasticsearch.monitoring.status', 1, tags=["method:total, component:elasticsearch"])
#        statsd.gauge('elasticsearch.monitoring.time', im , tags=["method:wait, component:elasticsearch"])
#        print im + response.took
         break
#      statsd.gauge('elasticsearch.monitoring.time', im , tags=["method:wait, component:elasticsearch"])
      i = i+1
      time.sleep(i)
      if delta >= abort_after:
        print 'error elasticsearch metrics could not be found'
        f = open("/checks/status/monasca_elasticsearch_test","w")
        f.write("1")
        f.close()
#        statsd.gauge('elasticsearch.monitoring.status', 0, tags=["method:get, component:elasticsearch"])
#        statsd.gauge('elasticsearch.monitoring.time', im, tags=["method:wait, component:elasticsearch"])
#        print im + response.took


storeMetric()
searchLoop()
{{ end }}
