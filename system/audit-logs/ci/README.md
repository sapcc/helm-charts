Run the credential-filter regression suite from a repository checkout:

```sh
python3 system/audit-logs/ci/test-audit-filters.py --fluentd-image <deployment-fluentd-image>
```

Requires Docker, Helm and yq v4. The Fluentd image must include the
`multi_format` parser, `record_modifier` filter and Prometheus plugin used by the
chart. The Logstash image defaults to `docker.elastic.co/logstash/logstash-oss:8.15.3`;
override it with `--logstash-image` when validating an image upgrade. Alert rules are
validated with `promtool` from `--prometheus-image` (default `prom/prometheus:v2.53.2`).

The suite renders both subcharts and runs their Kubernetes audit filters in
the real collector processes, with synthetic input and local stdout output.
Containers have no network access and mount only temporary test fixtures,
read-only. It checks credential-bearing resources, issued tokens/kubeconfigs,
JSON patches, multiple admission patch annotations, annotation-only events,
boolean removal markers and preservation of ordinary bodies and audit metadata.
It also checks that each collector counts the events whose credential bodies it
removed, which the `KubeAuditCredentialBodyRemoved` alerts watch: Logstash through
the `audit_credential_body_removed` step (`logstash_node_plugin_events_out_total`
from the bundled exporter), Fluentd through
`fluentd_audit_kubeapi_credential_body_removed_total`.

These filters protect the Gardener events received by `logstash-audit-external`
and the Kubernikus infrastructure container logs selected by
`fluent_audit_container.kubeAPIServer`. They remove all
`patch.webhook.admission.k8s.io/*` annotations, and the bodies of the listed
credential-bearing resources. `sap.cc.audit.credential_body_removed` marks only
events of those resources that carried a body or a patch annotation; patch
annotations on other objects are removed without it, because webhooks patch
ordinary objects such as shoots all the time.
Other annotations, including routing and authorization metadata, are retained.

Keep API-server audit policies safe as well: filtering happens after local audit
files have been written. Customer-configured Kubernikus destinations and stdout
streams not selected by this collector are outside these filters' coverage.
