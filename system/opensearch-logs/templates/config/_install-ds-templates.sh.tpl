#!/bin/bash

####
### Datastream template creation
####
if [ "${DATA_STREAM_ENABLED}" = true ]; then
   for e in ${DATA_STREAMS}; do
     export FILEPATH=/scripts
     export TMPPATH=/tmp
     export DS_TEMPLATE=ds.json

     echo "creating file FILE=${TMPPATH}/${e}"
     cp /${FILEPATH}/${DS_TEMPLATE} ${TMPPATH}/${e}-${DS_TEMPLATE}
     echo "Applying ${e}-${DS_TEMPLATE} to ${CLUSTER_HOST}"
     sed -i "s/_DS_NAME_/${e}/g" ${TMPPATH}/${e}-${DS_TEMPLATE}
     if  grep -q "$e" "${TMPPATH}/${e}-${DS_TEMPLATE}" ; then
         curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -H 'Content-Type: application/json' -XPUT "${CLUSTER_HOST}/_index_template/${e}-datastream" -d @${TMPPATH}/${e}-${DS_TEMPLATE}
         echo "\nUpload of ds template for datastream ${e} done"
     else
       echo "\n${TMPPATH}/${e}-${DS_TEMPLATE} is missing or the replacement was not successful."
       exit 1
     fi
   done;

       ####
   ### Datastream ism template creation
   ####
   # simple script to update ism ds policy.
   # Important steps:
   # Two values retrieved from the database have to be set to upload an ism ds policy
   # PRIM_TERM and SEQ_NUMBER have to be retrieved and used during upload.
   # To not upload the template everytime we set a version number in the secrets and compare this value with
   # the _version number of an installed ds template (auto incremented by the database).
   #
   # This script is used for OpenSearch logs
   #
   # After a new ds ism template is installed, it is only active after a rollover of the datastream, This means after the default 24h period or a manuall rover, which can also be triggered by a job.
   echo "Datastream ism template creation"
   for e in ${DATA_STREAMS}; do
     export DS_ISM_TEMPLATE=ds-ism.json
     cp /${FILEPATH}/${DS_ISM_TEMPLATE} ${TMPPATH}/${e}-${DS_ISM_TEMPLATE}
     echo "Applying ${e}-${DS_ISM_TEMPLATE} to ${CLUSTER_HOST}"
     sed -i "s/_DS_NAME_/${e}/g" ${FILEPATH}/${e}-${DS_ISM_TEMPLATE}
     sed -i "s/_SCHEMAVERSION_/${SCHEMA_VERSION}/g" ${TMPPATH}/${e}-${DS_ISM_TEMPLATE}
     # initial upload or test if ism policy exists
     export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism")
     echo -e "\nReturn code is $POLICY_RETURN_CODE\n"
     if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
        # 1. Part: install of new ds policy
        echo -e "inital upload of ds policy\n"
        echo -e "Upload ds policy, there is no policy "ds-${e}-ism" installed\n"
        curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism" -H 'Content-Type: application/json' -d @${TMPPATH}/${e}-${DS_ISM_TEMPLATE}
     else
       # update of existing policy
       # update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
       # Only update ism template, if schema_version has a new version number

       export CLUSTER_RETENTION_RESPONSE=$(curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism")
       export CLUSTER_RETENTION_SCHEMA_VERSION=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq .policy.schema_version?)
       export CLUSTER_RETENTION_RUN_PRIM_TERM=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._primary_term?)
       export CLUSTER_RETENTION_SEQ_NUMBER=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._seq_no?)

       echo -e "\nsecret file schema_version: ${FILE_RETENTION_SCHEMA_VERSION}"
       echo -e "\nsecret installed schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"

       if [ "${FILE_RETENTION_SCHEMA_VERSION}" -gt "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
         echo -e "\nupload of new ism template with primary number: ${CLUSTER_RETENTION_RUN_PRIM_TERM} and existing sequence number: ${CLUSTER_RETENTION_SEQ_NUMBER}\n"
         curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @${TMPPATH}/${e}-${DS_ISM_TEMPLATE}
         export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism"|jq .policy.schema_version?)
         echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new ism policy for ds-${e}-ism\n"
       else
         echo "No changes, ism template is not updated. Increase the version number to upload a new ism template"
       fi
    fi
  done
fi
