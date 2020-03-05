# Hermes OpenStack Auditing

[Hermes](https://github.com/sapcc/hermes/)

Important Note:

Hermes utilizes Persistent Volumes for ElasticSearch. These PV's are set to RECYCLE, so when they are no longer used, they are deleted and available for other pods.

Deployment with the --force option will delete all data from the Data Store. Deployment with the --force option should not be used, and care must be taken to validate all data is available.

Some tools for working with the elk stack are available in the elktools directory.  Currnetly the tool supports an elasticsearch restore from swift.  Instructions on using the elktools can be found here: (https://github.com/sapcc/hermes/elktools/README.md)