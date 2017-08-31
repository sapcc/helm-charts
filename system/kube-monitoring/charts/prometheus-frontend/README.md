# Prometheus Alerting

## Labels

Prometheus alerts can be enriched with metadata using labels. Using these labels Prometheus can be configured to route, group and inhibit alerts. The labels are then again used to render the alerting notification you see in Slack. The configuration depends on the following labels:

  * Region
  * Severity
  * Tier
  * Service
  * Context
  * Dashboard
  * Playbook
  * Meta

We are using the following conventions.

### Region

Region is an implicit label that is automatically set by Prometheus. Do not overwrite.

### Severity

  * `critical` Human action required. Situation requires attention as soon as possible.
  * `warning` Human action required. Situation requires attention but can wait for regular business hours.
  * `info` Alert does not require immediate attention.

### Tier

`tier` groups the alerts coarsly. We use:

   * `kubernetes`
   * `openstack`
   * `datapath`
   * `kubernikus`

### Service

The `service` label is used group alerts into logical sets. It should be a logical sub-system belonging to the `tier`. E.g. for `tier=openstack` we set `service=neutron`, `service=manila`, ...

The label is used for grouping alerts. Grouping means that all alerts that appear roughly in the same (currently 5min) time will be combined into a single notification. Groups will be by `region`/`tier`/`service`.

Additionally, the label is used for routing and inhibition.

### Context

The idea here is that `severity=critical` alerts are more important than `severity=warning`. Send both is unnecessary, so only the `critical` alert will be send.

The `context` label is used grouping these inhibitions. Put alerts for similar events with different `severity` in the same `context`.

For example:

  * `context=diskspace`,`serverity=critical`
  Disk 100% full. We are doomed.
  * `context=diskspace`.`severity=warning`
  Disk 80% full. We will be doomed in 3 days...

Both alerts will fire at the same time, but only the `critial` one will actually create a Slack notification.

## Dashboard

If there is a Grafana Dashboard relevant for this alert, you can add its name in the `dashboard` label. It's possible to expand variables:

```
dashboard="kubernetes-node?var-server={{`{{$labels.instance}}`}}"
```

The regional grafana prefix will be added automatically to the URL.

## Playbook

This will render a link to a playbook into the alert.

Example: `playbook="{{.Values.ops_docu_url}}/docs/support/playbook/k8s_node_not_ready.html"`

It can be any link. Preferrably it links to the OpsDocu: https://github.wdf.sap.corp/monsoon/convergedcloud-opsdocu-ui/tree/master/source/docs/support/playbook

## Sentry

If there is a Sentry project relevant for this alert, you can add its name in the `sentry` label.

```sentry = "Blackbox"```

The regional Sentry prefix will be added automatically to the URL.

## Routing

The alerts will be routed into a hierachy of Slack channels:

  * #{tier}-{severity}
  * #{tier}-{service}

This means:
  * #kubernetes-{info|warning|critical}
  * #openstack-{info|warning|critical}
  * #openstack-{neutron|nova|designate|...}

## Meta

The meta label will be used in the Alert Overview Dashboard to display additional information beside the alert name.

```
meta="{{ $labels.check }}"
```

## Guidelines

### Alert Names

Despite each alert being enriched with labels it makes sense to have a convention on how to craft the alert's name. Labels are only accessible in Prometheus configuration or can be inferred from the notification.

Use the following naming convention: `Tier` `Service` `Description`

For example:

  * `Kubernetes` `Scheduler` `ScrapeMissing`
  * `Openstack` `Nova` `StorageCrunchSoon`
  * `Datapath` `ACI` `PolutedNATTable`

### Understandable Alerts

Write you alerts in a way that can be understood by non-experts.

### Predict Failures

Try to write alerts that predict failures. This allows us to intervene before an actual situation appears. Where applicable it often makes sense to have a `critical` and `warning` version of each alert.

Imagine:

  * `context=diskspace`,`serverity=warning`,`predict_linear(node_filesystem_free[1h], 4*3600) < 0`
    Disk will full in 4 hours... Impeding doom. Do something soon!

  * `context=diskspace`,`serverity=critical`,`node_filesystem_free = 0`
    Disk 100% full. We are doomed.

Here we will get the `diskfull` alert before the problem actually appears.

### False Positives

Be careful not to create false-positives. This requires tuning of the sensitivity of the alerts. Keep in mind that `critical` alerts should only be fired when an actual human interaction is required. An alert that flaps to easily between broken and working without actually requires attention is such a false-positive.

This is often a tradeoff between the alert being detected and the notification firing. It's not easy to give general advise how to find the sweet spot. Though, it turned out to be workable to constanly tune the alerts whenever a false-positive appears. With automatic deployment of the alerts via the pipelines this is easy to do.

It also often requires to swallow individual failures. If it is desirable to see every single failure, create two alerts using the same `context`. Put the more sensitive one on `severity=warning` and the other on `severity=critical`

### Grouping of Rules

Put related alerts in their own `*.alert` file.
