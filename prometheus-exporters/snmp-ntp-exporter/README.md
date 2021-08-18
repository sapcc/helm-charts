snmp-ntp-exporter
----

This helm-chart expands the the [snmp-exporter](https://github.com/prometheus/snmp_exporter)
to be able to export unsupported values. Currently, snmp-exporter can't handle HEX or string
conversions to other types as the maintainers are not willing/plan to support
[custom types](https://github.com/prometheus/snmp_exporter/issues/466).

Therefore, another [fork](https://github.com/sapcc/snmp_exporter)
is used to support our custom values.

There's also a how-to development guide [here](https://github.wdf.sap.corp/I541794/documents/blob/master/NTP/snmp-ntp-exporter-development.md),
which explains in more detail how to support new values.

## Alerts
The alerts are located in the `alerts/`. The filename of the alerts is important as is used
by helm to decide if the alert is going to be deployed or not. To select which alert(s) is going to
be deployed you need to set the `snmp_exporter.alerts.routerModel` variable accordingly.

For example, assume that in the `alerts/` folder there are the following files:
- snmp-ntp-cisco-asr04.alerts
- snmp-ntp-cisco-n7k.alerts
- snmp-ntp-arista.alerts

Then the `snmp_exporter.alerts.routerModel` variable can contain any string that matches a single
or multiple alerts. For example:

Expected result | routerModel value | Alerts deployed
-|-|-
Deploy only `asr04` | `asr04` | snmp-ntp-cisco-asr04.alerts
Deploy only `n7k` | `n7k` | snmp-ntp-cisco-n7k.alerts
Deploy only arista | `arista` | snmp-ntp-arista.alerts
Deploy all cisco | `cisco` | snmp-ntp-cisco-asr04.alerts <br />snmp-ntp-cisco-n7k.alerts
Deploy all | `snmp-ntp` | snmp-ntp-cisco-asr04.alerts <br />snmp-ntp-cisco-n7k.alerts <br />snmp-ntp-arista.alerts

Therefore, as you can see you can use a proper naming convention to create tags that can be used
to deploy selected multiple configurations.

> Note: Since the `contains` helm function is used, then you need to be carefull in cases like that
the variable is used in `routerModel` may be contained as part of another alert namefile. Therefore,
it's best practice that the filenames are descriptive.