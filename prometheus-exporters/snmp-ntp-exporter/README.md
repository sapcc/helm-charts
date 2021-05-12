snmp-ntp-exporter
----

This helm-chart expands the the [snmp-exporter](https://github.com/prometheus/snmp_exporter)
to be able to export unsupported values. Currently, snmp-exporter can't handle HEX or string
conversions to other types as the maintainers are not willing/plan to support
[custom types](https://github.com/prometheus/snmp_exporter/issues/466).

Therefore, another [fork](https://github.com/dimtass/snmp_exporter/tree/support_NTPUnsignedTimeValue)
is used to support our custom values.

There's also a how-to development guide [here](https://github.wdf.sap.corp/I541794/snmp-exporter-development),
 which explains in more detail how to support new values.