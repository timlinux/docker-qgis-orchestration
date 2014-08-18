#!/bin/bash

date > /tmp/qgis-demo-server-log.txt

DIR=`dirname $0`
source ${DIR}/functions.sh

# Call this function with a unique client ID which 
# will be prefixed to the container name - and thus
# give you a QGIS session with the context of that client
CLIENT_ID=$1

# Any short lived container jobs go here

# Run the QGIS desktop client
run_qgis_desktop_container ${CLIENT_ID}
