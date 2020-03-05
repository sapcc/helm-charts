#!/usr/bin/env python
from elasticsearch import Elasticsearch, RequestsHttpConnection, NotFoundError, ConnectionError
from elasticsearch_dsl import Search
from datetime import datetime
from pytz import timezone
import time
import sys
from datadog import initialize, statsd

es = Elasticsearch(
['{{.Values.global.endpoint_host_internal}}:{{.Values.global.http_port}}'],
 connection_class=RequestsHttpConnection,
http_auth=('{{.Values.global.admin_user}}', '{{.Values.global.admin_password}}'),
use_ssl=False)

initialize(statsd_host='blackbox-tests-canary.blackbox.svc.kubernetes.scaleout.{{.Values.global.region}}.cloud.sap', statsd_port=9125)

fmt = "%Y-%m-%d %H:%M:%S %Z%z"
now_utc = datetime.utcnow()
now_cet = datetime.now(timezone('Europe/Berlin'))
index_date = now_utc.strftime('%Y.%m.%d')
check_rs = 'Monitoring check at: %s' % now_cet.strftime(fmt)
#print str(check_rs)

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
     print ("%s Elasticsearch Monitoring check, Elasticsearch host not found while sending logs entry to elasticsearch service: 404" % datetime.now(timezone('Europe/Berlin')))
     print(ce)
     statsd.gauge('blackbox_canary_status', 1, tags=["check:elasticsearch"])
     sys.exit(0)
  except Exception as e:
     print("%s Elasticsearch Monitoring check, Elasticsearch error while sending logs entry" % datetime.now(timezone('Europe/Berlin')))
     print(e)
     statsd.gauge('blackbox_canary_status', 1, tags=["check:elasticsearch"])
     sys.exit(0)
  else:
     statsd.gauge("blackbox_canary_status", 0, tags=["check:elasticsearch"])



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
       print ("%s Elasticsearch Monitoring check, Elasticsearch host not found while searching for log entry: 404" % datetime.now(timezone('Europe/Berlin')))
       print(nf)
       statsd.gauge('blackbox_canary_status', 1, tags=["check:elasticsearch"])
       sys.exit(0)
      except Exception as e:
       print("%s Elasticsearch Monitoring check, Elasticsearch error while searching for log entry" % datetime.now(timezone('Europe/Berlin')))
       print(e)
       statsd.gauge('blackbox_canary_status', 1, tags=["check:elasticsearch"])
       sys.exit(0)

      if response.success() == True and response.hits.total == 1:
        print('%s Elasticsearch Monitoring check, response time: %sms' % (datetime.now(timezone('Europe/Berlin')), response.took))
        statsd.gauge('blackbox_canary_status', 0, tags=["check:elasticsearch"])
        statsd.gauge('blackbox_canary_duration', response.took, tags=["check:elasticsearch"])
        break
      i = i+1
      time.sleep(i)
      if delta >= abort_after:
        print ('%s Elasticsearch Monitoring check, error elasticsearch metrics could not be found' % datetime.now(timezone('Europe/Berlin')))
        statsd.gauge('blackbox_canary_status', 1, tags=["check:elasticsearch"])
        statsd.gauge('blackbox_canary_duration', im, tags=["check:elasticsearch"])


storeMetric()
searchLoop()
