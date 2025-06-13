This helm chart is used to deploy the global landing page for https://juno.global.cloud.sap/, https://ccloud.global.cloud.sap/ and https://convergedcloud.global.cloud.sap/

# DNS entries

These dns entries are managed in `qa-de-1` for QA and `eu-nl-1` ccadmin master project

# QA

It is deployed to `qa-de-1` elektra namespace

# Production

It is deploys in the elektra namespace in `eu-nl-1`.

# Functionality

The nginx is configured to serve the static content of the landing page from elektra dashboard within the region where it is deployed.

The request to elektra is `https://dashboard.{{ .Values.global.region }}.cloud.sap/assets/landing_page_widget.js?ts={{ now }}" data-prodmode="true"`
