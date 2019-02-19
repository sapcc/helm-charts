# Hermes OpenStack Auditing

[Hermes](https://github.com/sapcc/hermes/)

Important Note:

Hermes utilizes Persistent Volumes for ElasticSearch. These PV's are set to RECYCLE, so when they are no longer used, they are deleted and available for other pods.

Deployment with the --force option will delete all data from the Data Store. Deployment with the --force option should not be used, and care must be taken to validate all data is available.