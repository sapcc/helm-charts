This helm chart is used to deploy the global landing page for https://juno.global.cloud.sap/, https://ccloud.global.cloud.sap/ and https://convergedcloud.global.cloud.sap/

# DNS entries

These dns entries are managed in `eu-de-1` ccadmin master project

# Deployment

It deploys an nginx in `s-eu-nl-1` with special configuration to serve the static content of the landing page from elektra dashboard within the `eu-nl-1` region
