# AWX-API-CRAWLER

This Helm Chart contains a k8s job to fetch AWX API regular basis.

# DEPLOYMENT

- edit the job script on  `src/main.py`
- `cd ./src` & `make build`
- 
```bash
docker login keppel.eu-de-1.cloud.sap
Username: IXXXXX@ccadmin/InfraAutomation@ccadmin
Password: YOURPASSWORD
```