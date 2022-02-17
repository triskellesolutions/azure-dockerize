#!/bin/bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -uo pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

saPassword="$1"



sudo docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=${saPassword}" \
   --restart always \
   --name sql1 -h sql1 \
   -p 1433:1433 \
   -d mcr.microsoft.com/mssql/server:2019-latest
