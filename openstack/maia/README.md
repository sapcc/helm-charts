# Maia OpenStack Prometheus Service

[Maia](https://github.com/sapcc/maia/)

Important Note:

Maia utilizes Persistent Volumes. These PV's are set to RECYCLE, so when they are no longer used, they are deleted and available for other pods.

Deployment with the --force option will delete all data from the Data Store. Deployment with the --force option should be used with caution, and care must be taken to validate all data is available.