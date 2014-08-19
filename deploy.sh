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

LOG_FILE=${1}.log
if [ ! -f LASTPORT.txt ]
then
   # Save old log as a temp file
   OLD_LOG=${1}.$$.log
   echo "Moving old log to ${OLD_LOG}" 
   mv ${LOG_FILE} ${OLD_LOG}
fi
echo "Orchestrating containers for ${1}" > ${LOG_FILE}
echo "" >> ${LOG_FILE}
date >> ${LOG_FILE}


if test -z "$2"
then
  run_btsync_container $1
  run_postgis_container $1
  run_qgis_server_container $1
else
  run_storage_container $1
  run_postgis_container $1
  run_qgis_server_container $1
fi
echo "" >> ${LOG_FILE}
echo "Containers running for client: ${1}" >> ${LOG_FILE}
echo "==========================================" >> ${LOG_FILE}

docker ps -a | grep $1 >> ${LOG_FILE}

cat ${LOG_FILE}
