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

mssqlPassword="$1"
remoteUrl="$2"

installScript() {
    local fileName="$1"
    local filePath="$2"
    local remoteUrl="$3"
    sudo touch $filePath$fileName
    sudo chmod 777  $filePath$fileName
    sudo curl -sl "${remoteUrl}/${fileName}" > $filePath/$fileName
    sudo chown root:root $filePath$fileName
    sudo chmod 600  $filePath$fileName
    sudo chmod +x  $filePath$fileName
}

sudo apt-get update
sudo apt-get install nginx

sudo unlink /etc/nginx/sites-enabled/default
code=0 && response=$(sudo mkdir -p /etc/nginx/sites-available 2>&1) || code=$?
if [ -d '/etc/nginx/sites-available/']; then
    installScript reverse-proxy.conf '/etc/nginx/sites-available' "$remoteUrl"
fi
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
sudo service nginx configtest
sudo service nginx restart



sudo docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=${mssqlPassword}" \
   --restart always \
   --name sql1 -h sql1 \
   -p 1433:1433 \
   -d mcr.microsoft.com/mssql/server:2019-CU14-ubuntu-18.04


sudo docker run \
    --name aspnet_sample -h aspnet_sample \
    --expose=80 --expose=443 \
    -d mcr.microsoft.com/dotnet/samples:aspnetapp

sudo docker run \
    --name aspnet_sample1 -h aspnet_sample1 \
    --expose=80 --expose=443 \
    -d mcr.microsoft.com/dotnet/samples:aspnetapp