#!/bin/bash
source functions.sh

echo ""
echo "----------------------------------------"
echo "This script will deploy QGIS Demo Server"
echo "images as a series of docker containers"
echo "----------------------------------------"
echo ""

if test -z "$1"
then
  echo "usage: $0 <client_id> [local_storage]"
  echo "e.g. : $0 798791"
  echo "To use local only storage (not btsync) do e.g.:"
  echo "e.g. : $0 kartoza yes"
  exit
fi

if test -z "$2"
then
  run_storage_container $1
  run_postgis_container $1
  run_qgis_server_container $1
else
  run_btsync_container $1
  run_postgis_container $1
  run_qgis_server_container $1
fi

