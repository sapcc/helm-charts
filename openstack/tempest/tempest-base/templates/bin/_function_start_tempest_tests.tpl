{{- define "tempest-base.function_start_tempest_tests" }}

function start_tempest_tests {

  echo -e "\n === PRE-CONFIG STEP  === \n"

  export OS_USERNAME={{ default "neutron-tempestadmin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name | quote }}
  export OS_TENANT_NAME={{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_project_name | quote }}
  export OS_PROJECT_NAME={{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_project_name | quote }}
  export IMAGE_REF=$(openstack image list | grep {{ default "cirros-vmware" (index .Values (print .Chart.Name | replace "-" "_")).tempest.image_ref }} | awk {' print $2 '})
  export IMAGE_REF_ALT=$(openstack image list | grep {{ default "ubuntu-16.04-amd64-vmware" (index .Values (print .Chart.Name | replace "-" "_")).tempest.image_ref_alt }} | awk {' print $2 '})
  cp /{{ .Chart.Name }}-etc/tempest_extra_options /tmp
  sed -i "s/CHANGE_ME_IMAGE_REF/$(echo $IMAGE_REF)/g" /tmp/tempest_extra_options
  sed -i "s/CHANGEMEIMAGEREFALT/$(echo $IMAGE_REF_ALT)/g" /tmp/tempest_extra_options

  echo -e "\n === CONFIGURING RALLY & TEMPEST === \n"

  # init exit code vars
  export TEMPEST_EXIT_CODE=0
  export RALLY_EXIT_CODE=0

  # ensure rally db is present
  rally db ensure
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # configure deployment for current region with existing users
  rally deployment create --file /{{ .Chart.Name }}-etc/tempest_deployment_config.json --name tempest_deployment
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # check if we can reach openstack endpoints
  rally deployment check
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # create tempest verifier fetched from our repo
  rally --debug verify create-verifier --type tempest --name {{ .Chart.Name }}-verifier --system-wide --source https://github.com/sapcc/tempest --version ccloud-train
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # configure tempest verifier taking into account the auth section values provided in tempest_extra_options file
  # use config file from PRE_CONFIG STEP from /tmp directory
  rally --debug verify configure-verifier --extend /tmp/tempest_extra_options
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # run the actual tempest tests for neutron
  echo -e "\n === STARTING TEMPEST TESTS FOR {{ .Chart.Name }} === \n"
  rally --debug verify start --concurrency {{ default "1" .Values.concurrency }} --detailed --pattern '{{ required "Missing run_pattern value!" .Values.run_pattern }}' --skip-list /{{ .Chart.Name }}-etc/tempest_skip_list.yaml --xfail-list /{{ .Chart.Name }}-etc/tempest_expected_failures_list.yaml
  RALLY_EXIT_CODE=$(($RALLY_EXIT_CODE + $?))

  # generate html report
  rally verify report --type html --to /tmp/report.html

  # upload report and logfile to swift container of neutron-tempestadmin1 as there is a permalink in the slack message
  export OS_USERNAME="neutron-tempestadmin1"
  export OS_TENANT_NAME="neutron-tempest-admin1"
  export OS_PROJECT_NAME="neutron-tempest-admin1"
  export MYTIMESTAMP=$(date -u +%Y%m%d%H%M%S)
  cd /home/rally/.rally/verification/verifier*/for-deployment* && tar cfvz /tmp/tempest-log.tar.gz ./tempest.log && cd /home/rally/source/
  openstack object create reports/{{ index (split "-" .Chart.Name)._0 }} /tmp/tempest-log.tar.gz --name $(echo $OS_REGION_NAME)-$(echo $MYTIMESTAMP)-log.tar.gz
  openstack object create reports/{{ index (split "-" .Chart.Name)._0 }} /tmp/tempest-log.tar.gz --name $(echo $OS_REGION_NAME)-log-latest.tar.gz
  openstack object create reports/{{ index (split "-" .Chart.Name)._0 }} /tmp/report.html --name $(echo $OS_REGION_NAME)-$(echo $MYTIMESTAMP).html
  openstack object create reports/{{ index (split "-" .Chart.Name)._0 }} /tmp/report.html --name $(echo $OS_REGION_NAME)-latest.html
}

{{- end }}

{{- define "tempest-base.function_main" }}

main() {
  start_tempest_tests
  # check if rally had a problem, if not grab the failures and eventually set the exit code for tempest results
  if [[ $RALLY_EXIT_CODE -eq 0 && $(rally verify show --uuid $(rally verify list | grep "tempest" | awk '{ print $2 }') --detailed | grep -E "Failures" | awk '{ print $4 }') -gt 0 ]]; then 
  	export TEMPEST_EXIT_CODE=1
  fi
  cleanup_tempest_leftovers
  export CLEANUP_EXIT_CODE=$?
  rally verify show --uuid $(rally verify list | grep "tempest" | awk '{ print $2 }')
  exit $(($RALLY_EXIT_CODE + $TEMPEST_EXIT_CODE + $CLEANUP_EXIT_CODE))
}

{{- end }}
