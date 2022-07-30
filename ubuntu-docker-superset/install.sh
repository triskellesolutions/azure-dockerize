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

supersetAdminUser=$1
supersetAdminUserPassword=$2
supersetDomainName=$3
remoteFileUrl=$4

sudo apt-get update -y
sudo apt-get upgrade -y

# automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades

echo "---------------------------------------------------------------------------"
echo "- Install certbot"
echo "---------------------------------------------------------------------------"
sudo apt install snapd
sudo snap install core; sudo snap refresh core;
sudo apt-get remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo certbot certonly --standalone --agree-tos --email certbot@triskelle.solutions -d $supersetDomainName

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

install Script superset_config.py $PWD "$remoteFileUrl"

# -e "SUPERSET_OAUTH_KEY=" \
# -e "SUPERSET_OAUTH_SECRET=" \
# -e "SUPERSET_OAUTH_WHITELIST=" \
# -e "SUPERSET_HOME=/home/superset" \

sudo docker run \
   --restart always \
   --name superset \
   -p 80:8088 \
   -p 443:8088 \
   -v ./superset_config.py:/etc/superset/superset_config.py
   -d apache/superset

sudo docker exec -it superset superset fab create-admin \
   --username $supersetAdminUser \
   --firstname Superset \
   --lastname Admin \
   --email superset.admin@triskelle.solutions \
   --password $supersetAdminUserPassword 

sudo docker exec -it superset superset db upgrade
sudo docker exec -it superset superset load_examples
sudo docker exec -it superset superset init
