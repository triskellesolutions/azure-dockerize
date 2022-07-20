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

sudo apt-get update -y
sudo apt-get upgrade -y

# install cockpit
sudo apt -y install cockpit
sudo systemctl --now enable cockpit.socket
sudo ufw allow 9090/tcp

# automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades
# enforce a strong root password.
sudo apt install libpam-cracklib
# blocks any IP addresses for 10 minutes that attempt more than 3 password retries
sudo apt install fail2ban

echo "---------------------------------------------------------------------------"
echo "- Install certbot"
echo "---------------------------------------------------------------------------"
sudo snap install core; sudo snap refresh core;
sudo apt-get remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo certbot certonly --standalone --agree-tos --email certbot@triskelle.solutions -d $supersetDomainName

sudo mkdir -p /etc/letsencrypt/deploy/
sudo touch /etc/letsencrypt/deploy/update_cockpit_certificate.sh


echo "#!/bin/bash                                                                                                             " | sudo tee -a /etc/letsencrypt/deploy/update_cockpit_certificate.sh
echo "  DOMAIN=$supersetDomainName                                                                                                    " | sudo tee -a /etc/letsencrypt/deploy/update_cockpit_certificate.sh
echo "# Copy cert for cockpit                                                                                                 " | sudo tee -a /etc/letsencrypt/deploy/update_cockpit_certificate.sh
echo "  sudo install -m 644 /etc/letsencrypt/live/\$DOMAIN/fullchain.pem /etc/cockpit/ws-certs.d/1-letsencrypt.cert           " | sudo tee -a /etc/letsencrypt/deploy/update_cockpit_certificate.sh
echo "  sudo install -m 640 -g cockpit-ws /etc/letsencrypt/live/\$DOMAIN/privkey.pem /etc/cockpit/ws-certs.d/1-letsencrypt.key" | sudo tee -a /etc/letsencrypt/deploy/update_cockpit_certificate.sh

sudo systemctl stop cockpit.service
sudo chmod a+x /etc/letsencrypt/deploy/update_cockpit_certificate.sh                                                                                                                  "

sudo docker run \
   --restart always \
   --name superset \
   -p 80:8080 \
   -d apache/superset

sudo docker exec -it superset superset fab create-admin \
   --username "$supersetAdminUser" \
   --firstname Superset \
   --lastname Admin \
   --email superset.admin@triskelle.solutions \
   --password "$supersetAdminUserPassword"

sudo docker exec -it superset superset db upgrade
sudo docker exec -it superset superset load_examples
sudo docker exec -it superset superset init
