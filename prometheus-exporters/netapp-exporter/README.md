## Change Log

### v0.2.0

#### netapp-harvest-exporter
  - Runs in master-worker mode
  - Master provide scraping target for workers via API.
  - Each worker runs a Harvest poller, which is responsible for a single Filer.
  - The scraped metrics are monitored by Master.
  - Manila exporters in are disabled atm

### v0.2.1

#### netapp-harvest-exporter
  - Prometheus alert on not enough workers
