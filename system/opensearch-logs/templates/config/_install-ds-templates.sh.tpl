#!/bin/bash

export CLUSTER_HOST_BASE=$(echo ${CLUSTER_HOST} | sed -E 's|https://([^:/]+).*|\1|')

# Create a temporary netrc file
export NETRC_FILE=$(mktemp)
trap "rm -f ${NETRC_FILE}" EXIT

####
##Check which admin user is active
####
echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN_USER} password ${ADMIN_PASSWORD}" > "${NETRC_FILE}"
curl -s --netrc-file "${NETRC_FILE}" "${CLUSTER_HOST}/"
if [ $? -ne 0 ]; then
  echo "First user failed, trying second user"
  # Second attempt with user2 if user1 fails
  echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN2_USER} password ${ADMIN2_PASSWORD}" > "${NETRC_FILE}"
  curl -s --netrc-file "${NETRC_FILE}" "${CLUSTER_HOST}/"
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  fi
fi

####
### Datastream template creation
####
if [ "${DATA_STREAM_ENABLED}" = true ]; then
   for e in ${DATA_STREAMS}; do
     export FILEPATH=/scripts
     export TMPPATH=/tmp
     export DS_TEMPLATE=ds.json
     export DS_ISM_TEMPLATE=ds-${e}-ism.json
     export DS_NAME=`echo ${e}|awk -F# '{ print $1 }'`
     export DS_SHARD=`echo ${e}|awk -F# '{ print $2 }'`

     echo "creating file FILE=${TMPPATH}/${e}"
     cp "/${FILEPATH}/${DS_TEMPLATE}" "${TMPPATH}/${e}-${DS_TEMPLATE}"
     echo "Applying ${e}-${DS_TEMPLATE} to ${CLUSTER_HOST}"
     sed -i "s/_DS_NAME_/${e}/g" "${TMPPATH}/${e}-${DS_TEMPLATE}"
     if  grep -q "$e" "${TMPPATH}/${e}-${DS_TEMPLATE}" ; then
         curl --netrc-file "${NETRC_FILE}" -H 'Content-Type: application/json' -XPUT "${CLUSTER_HOST}/_index_template/${e}-datastream" -d @"${TMPPATH}/${e}-${DS_TEMPLATE}"
         echo -e "\nUpload of ds template for datastream ${e} done"
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
     # we have to copy the template from the scripts secrets to a directory, where we can change the template.
     cp "/${FILEPATH}/${DS_ISM_TEMPLATE}" "${TMPPATH}/${DS_ISM_TEMPLATE}"
     echo "Applying ${TMPPATH}/${DS_ISM_TEMPLATE} to ${CLUSTER_HOST}"

     # initial upload or test if ism policy exists
     export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism")
     echo -e "\nReturn code is $POLICY_RETURN_CODE\n"
     if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
        # 1. Part: install of new ds ism policy
        echo -e "inital upload of datastream ism policy"
        echo -e "Upload ds policy, there is no policy \"ds-${e}-ism\" installed"
        curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism" -H 'Content-Type: application/json' -d @"${TMPPATH}/${DS_ISM_TEMPLATE}"

        # 2. create datastream, if missing. It's done here, because the normal template has no versioning and can be overwritten during each run.
        #    data_stream example: otellogs-datastream

        export EXISTING_DS=`curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_data_stream"|jq .data_streams[].name|awk ' {gsub("-datastream","") } 1'|tr  -d \"`
        echo "\nExisting datastreams: $EXISTING_DS\n"
        echo "$EXISTING_DS" | grep -q "^$e$"
        if [ $? -eq 1 ]; then
           echo "\nCreating datastream $e\n"
           curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_data_stream/${e}-datastream"
           # Assign ISM policy to newly created datastream
           curl --header 'content-type: application/JSON' --silent --netrc-file "${NETRC_FILE}" -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/.ds-${e}-datastream-000001" -d "{ \"policy_id\": \"ds-${e}-ism\" }"
        else
           echo "No datastream creation return code was not 1 for datastream $e"
        fi
     else
       # update of existing policy
       # update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
       # Only update ism template, if schema_version has a new version number

       export CLUSTER_RETENTION_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism")
       export CLUSTER_RETENTION_SCHEMA_VERSION=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq .policy.schema_version?)
       export CLUSTER_RETENTION_RUN_PRIM_TERM=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._primary_term?)
       export CLUSTER_RETENTION_SEQ_NUMBER=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._seq_no?)

       if [ -z "${FILE_RETENTION_SCHEMA_VERSION}" ]; then
         echo -e "Variable FILE_RETENTION_SCHEMA_VERSION is empty or not existing\n"
       else
         echo -e "secret env variable schema_version: ${FILE_RETENTION_SCHEMA_VERSION}"
       fi
       if [ -z "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
         echo -e "variable CLUSTER_RETENTION_SCHEMA_VERSION is empty or not existing\n"
       else
         echo "secret database schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"
       fi
       if [ "${FILE_RETENTION_SCHEMA_VERSION}" -gt "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
         #echo "Deleting old policy ds-${e}-ism"
         #curl --netrc-file "${NETRC_FILE}" -XDELETE "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism"
         echo -e "\nupload of new ism template with primary number: ${CLUSTER_RETENTION_RUN_PRIM_TERM} and existing sequence number: ${CLUSTER_RETENTION_SEQ_NUMBER}\n"
         curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${DS_ISM_TEMPLATE}"
         cat "${TMPPATH}/${DS_ISM_TEMPLATE}"
         export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/ds-${e}-ism"|jq .policy.schema_version?)
         echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new ism policy for ds-${e}-ism\n"
       else
         echo "No changes, ism template is not updated. Increase the version number to upload a new ism template"
       fi
    fi
  done
fi
