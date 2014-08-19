#!/bin/bash
source functions.sh

echo ""
echo "----------------------------------------"
echo "This script will kill QGIS Server"
echo "containers for a given client/customer  "
echo "----------------------------------------"
echo ""

if test -z "$1"
then
  echo "usage: $0 <client_id>"
  echo "e.g. : $0 798791"
  echo "e.g. : $0 kartoza"
  exit
fi

kill_client_containers $1

