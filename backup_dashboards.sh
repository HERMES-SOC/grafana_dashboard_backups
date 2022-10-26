#!/usr/bin/env bash

# Check if Environment Variables are set
[[ -z "${GRAFANA_TOKEN}" ]] && echo "GRAFANA_TOKEN Env Variable Not Set" || token="${GRAFANA_TOKEN}"

[[ -z "${GRAFANA_URL}" ]] && echo "GRAFANA_URL Env Variable Not Set" || grafanaurl="${GRAFANA_URL}"

# Get all of the dashboards from Grafana
out=$(curl -s -H "Authorization: Bearer $token" -X GET $grafanaurl/search?type=dash-db&query=%)

# Create Dashboards folder if it doesn't exist
mkdir -p dashboards

# Array of retrieved dashboards from API
dashboardsArr=()

# Array to store modified dashboards for PR
createdArr=()
modifiedArr=()
deletedArr=()

# Loop through each dashboard and create backup
for uid in $(echo $out | jq -r '.[] | .uid'); do

  # Get Dashboard JSON
  dash=$(curl -s -H "Authorization: Bearer $token" -X GET $grafanaurl/dashboards/uid/$uid)
  version=$(echo $dash | jq -r '.dashboard | .version' | sed -r 's/[ \/]+/_/g')

  # Parse Variables From JSON
  dash_version=$(curl -s -H "Authorization: Bearer $token" -X GET $grafanaurl/dashboards/uid/$uid/versions/$version)
  dashboard_title=$(echo $dash | jq -r '.dashboard | .title' | sed -r 's/[ \/]+/_/g')
  version_message=$(echo $dash_version | jq -r '.message' | sed -r 's/[ \/]+/_/g')
  version_created_by=$(echo $dash_version | jq -r '.createdBy' | sed -r 's/[ \/]+/_/g')
  
  # File name variables
  FILE=dashboards/grafana-dashboard-$uid.json
  TEMP_FILE=dashboards/temp-grafana-dashboard-$uid.json
  dashboardsArr+=("$FILE")
  dashChangeInfo=("Dashboard Title: $dashboard_title<br/>Dashboard UID: $uid<br/>Dashboard Version: $version<br/>Dashboard Version Message: $version_message<br/>Dashboard Version Created By: $version_created_by<br/><br/>")
  # Check if files have changed and update if they have
  # Check if dashboard file already exists
  if [ -f "$FILE" ]; then
    echo "$FILE exists."
    echo $dash >> $TEMP_FILE
    jq . $TEMP_FILE | sponge $TEMP_FILE

    if cmp --silent $FILE $TEMP_FILE ; then
       echo "Keeping file $FILE the same."
       rm $TEMP_FILE
    else 
       echo "Updating file $FILE."
       rm $FILE
       cat $TEMP_FILE >> $FILE
       rm $TEMP_FILE
       modifiedArr+=$dashChangeInfo
    fi
  else 
    # Create new file
    echo "$FILE does not exist."
    echo $dash >> $FILE
    jq . $FILE | sponge $FILE
    createdArr+=$dashChangeInfo
  fi
  echo "DASH $dashboard_title ($uid) EXPORTED"
done

# Handle removed dashboards
DASHBOARD_FILES="dashboards/*"

for f in $DASHBOARD_FILES
do
if [[ ! " ${dashboardsArr[*]} " =~ " $f " ]]; then
    echo "Removing $f"
    deletedArr+=("$f<br/>")
    rm $f
fi
done

# Update Github Actions Environment Variable
CREATED_INFO="<h3>Created Dashboards:</h3><br>${createdArr[*]}"
CREATED_NUMBER=${#createdArr[@]}
MODIFIED_INFO="<h3>Modified Dashboards:</h3><br>${modifiedArr[*]}"
MODIFIED_NUMBER=${#modifiedArr[@]}
DELETED_INFO="<h3>Deleted Dashboards:</h3><br>${deletedArr[*]}"
DELETED_NUMBER=${#deletedArr[@]}
echo "::set-env name=CREATED_INFO::$CREATED_INFO"
echo "::set-env name=CREATED_NUMBER::$CREATED_NUMBER"
echo "::set-env name=MODIFIED_INFO::$MODIFIED_INFO"
echo "::set-env name=MODIFIED_NUMBER::$MODIFIED_NUMBER"
echo "::set-env name=DELETED_INFO::$DELETED_INFO"
echo "::set-env name=DELETED_NUMBER::$DELETED_NUMBER"
