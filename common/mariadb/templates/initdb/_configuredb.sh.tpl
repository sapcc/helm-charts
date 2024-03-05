VERSION={{ .Values.pre_change_hook.kubectl_version }}
DEPLOYMENT_NAME={{ include "fullName" . }}

# Get the pod name associated with the deployment
# becuase the pod name is dynamic, and kubectl cp command is working only with pods 
# we need to get the pod name from the deployment

POD_NAME=$(kubectl-v${VERSION} get pods -l app=${DEPLOYMENT_NAME} -o jsonpath='{.items[0].metadata.name}')

echo "POD_NAME: ${POD_NAME}"

# Copy the file to the containers secret files can not be copied
echo "prepare file to copy"
cat /var/lib/initdb/init.sql > /tmp/init.sql

echo "Copying init.sql to ${POD_NAME}:/tmp/init.sql"
kubectl-v${VERSION} cp /tmp/init.sql ${POD_NAME}:/var/opt/initdb.sql -c mariadb

kubectl-v${VERSION} exec -c mariadb ${POD_NAME} -- cat /var/opt/initdb.sql
# Run the SQL script
echo "Running init.sql"
kubectl-v${VERSION} exec -c mariadb ${POD_NAME} -- mariadb -uroot --batch -e "source /var/opt/initdb.sql"
