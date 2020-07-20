# supernova-incident-contact-list

This chart provides the ConfigMap of the same name to Supernova. It's a
separate chart because the contact list values.yaml comes from a different Git
repo than our usual secrets. Our deployment process only supports so many
values repos at once, so we could not use our standard tooling if this
ConfigMap were deployed with the regular Supernova chart.

Having this in a separate chart is not a problem in practice. Supernova can
hot-reload the contact list file after changes, so no rolling restart of the
Supernova pods is needed when touching the ConfigMap.
