This helm chart is used to deploy the global landing page

# DNS entries

DNS entries are managed in `qa-de-1` for QA and `eu-nl-1` ccadmin master project

- https://juno.qa-de-1.cloud.sap
- https://juno.eu-nl-1.cloud.sap

`global.cloud.sap` is defined `eu-nl-1` ccadmin master project

- https://juno.global.cloud.sap
- https://ccloud.global.cloud.sap
- https://convergedcloud.global.cloud.sap

# QA

It is deployed to `qa-de-1` elektra namespace

# Production

It is deploys in the elektra namespace in `eu-nl-1`.

# Functionality

The nginx is configured to serve the static content of the landing page from elektra dashboard within the region where it is deployed.

The request to elektra is `https://dashboard.{{ .Values.global.region }}.cloud.sap/assets/landing_page_widget.js?ts={{ now }}" data-prodmode="true"`
