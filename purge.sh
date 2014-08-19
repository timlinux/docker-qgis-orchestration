#!/bin/bash
source functions.sh


if test -z "$1"
then
  echo "usage: $0 <client_id>"
  echo "e.g. : $0 798791"
  echo "e.g. : $0 kartoza"
  exit
fi
echo ""
echo "----------------------------------------"
echo "This script will remove host basedi storage"
echo "for containers for a client/customer: $1  "
echo "DATA WILL NOT BE RECOVERABLE!"
echo "----------------------------------------"
echo ""
echo "These directories will be removed:"
ls -lah ${BASE_PATH}/${1}*
read -p "Are you sure you want to continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    purge $1
fi


