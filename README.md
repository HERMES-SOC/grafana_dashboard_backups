# Grafana Dashboard Backups
### Description:
This repository stores deployed dashboards as JSON models on [https://grafana.hermes.swsoc.smce.nasa.gov/](https://grafana.hermes.swsoc.smce.nasa.gov/). It also contains a backup script that is used by the daily scheduled GitHub action. 

### Daily Scheduled Action:
When the GitHub Action is triggered, the backup script `backup_dashboards.sh` is executed. When there is a creation, change or deletion of any of the JSON models the script modifies the cloned repo within the container. Then a PR is created with the changes made from `main`.

### Github Secrets:
This action requires the secrets `GRAFANA_URL` and `GRAFANA_TOKEN` set.

`GRAFANA_URL` - The URL for your Grafana instance's API.

`GRAFANA_TOKEN` - API Token Key for your Grafana API.



