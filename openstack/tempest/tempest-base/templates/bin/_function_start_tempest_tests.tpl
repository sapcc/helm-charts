{{- define "tempest-base.function_start_tempest_tests" }}

function start_tempest_tests {

  echo -e "\n === PRE-CONFIG STEP  === \n"

  export OS_USERNAME='neutron-tempestadmin1'
  export OS_TENANT_NAME='neutron-tempest-admin1'
  export OS_PROJECT_NAME='neutron-tempest-admin1'
  export IMAGE_REF=$(openstack image list | grep {{ default "cirros-vmware" (index .Values (print .Chart.Name | replace "-" "_")).tempest.image_ref }} | awk {' print $2 '})
  export IMAGE_REF_ALT=$(openstack image list | grep {{ default "ubuntu-16.04-amd64-vmwaree" (index .Values (print .Chart.Name | replace "-" "_")).tempest.image_ref_alt }} | awk {' print $2 '})
  cp /{{ .Chart.Name }}-etc/tempest_extra_options /tmp
  sed -i "s/CHANGE_ME_IMAGE_REF/$(echo $IMAGE_REF)/g" /tmp/tempest_extra_options
  sed -i "s/CHANGE_ME_IMAGE_REF_ALT/$(echo $IMAGE_REF_ALT)/g" /tmp/tempest_extra_options

  echo -e "\n === CONFIGURING RALLY & TEMPEST === \n"

  # ensure rally db is present
  rally db ensure

  # configure deployment for current region with existing users
  rally deployment create --file /{{ .Chart.Name }}-etc/tempest_deployment_config.json --name tempest_deployment

  # check if we can reach openstack endpoints
  rally deployment check

  # create tempest verifier fetched from our repo
  rally --debug verify create-verifier --type tempest --name {{ .Chart.Name }}-verifier --system-wide --source https://github.com/sapcc/tempest --version ccloud

  # configure tempest verifier taking into account the auth section values provided in tempest_extra_options file
  # use config file from PRE_CONFIG STEP from /tmp directory
  rally --debug verify configure-verifier --extend /tmp/tempest_extra_options

  # run the actual tempest tests for neutron
  echo -e "\n === STARTING TEMPEST TESTS FOR {{ .Chart.Name }} === \n"
  rally --debug verify start --concurrency {{ default "1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.concurrency }} --detailed --pattern {{ if eq .Chart.Name "nova-tempest" }}tempest.api.compute{{ else if eq .Chart.Name "barbican-tempest"}}{{ .Chart.Name | replace "-" "_" }}_plugin.tests.api{{ else }}{{ .Chart.Name | replace "-" "_" }}_plugin.api{{ end }} --skip-list /{{ .Chart.Name }}-etc/tempest_skip_list.yaml --xfail-list /{{ .Chart.Name }}-etc/tempest_expected_failures_list.yaml

  # generate html report
  rally verify report --type html --to /tmp/report.html

  # upload report and logfile to swift container of neutron-tempestadmin1
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
  if [ $(rally verify show --uuid $(rally verify list | grep "tempest" | awk '{ print $2 }') --detailed | grep -E "Failures" | awk '{ print $4 }') -gt 0 ]; then 
  	export TEMPEST_EXIT_CODE=1
  else
  	export TEMPEST_EXIT_CODE=0
  fi
  cleanup_tempest_leftovers
  export CLEANUP_EXIT_CODE=$?
  rally verify show --uuid $(rally verify list | grep "tempest" | awk '{ print $2 }')
  exit $(($TEMPEST_EXIT_CODE + $CLEANUP_EXIT_CODE))
}

{{- end }}