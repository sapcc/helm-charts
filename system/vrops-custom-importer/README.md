vrops-custom-importer
--------------

Installs the [vrops-custom-importer](https://github.tools.sap/cia/vrops-custom-importer) operator which import custom VMWare metrics to vROps.

The executable iterates through all VCenters in the region and collects custom metrics from VMs, Cluster and ESXI. The information about VMs, ESXI and VCenters are fetched from VCenters using the vSphere API. The custom metrics are then imported to vROps using the vROps API.

## Configuration

See [values](./values.yaml).
