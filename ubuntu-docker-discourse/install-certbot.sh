echo "---------------------------------------------------------------------------"
echo "- Install certbot"
echo "---------------------------------------------------------------------------"
sudo snap install core; sudo snap refresh core;
sudo apt-get remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

echo "---------------------------------------------------------------------------"
echo "- TODO: certbot configuration"
echo "-     Complete the following "
echo "---------------------------------------------------------------------------"
echo "# https://certbot.eff.org/instructions?ws=other&os=ubuntubionic"
echo "# sudo certbot certonly --standalone --agree-tos --email YOUR-EMAIL-ADDRESS -d COCKPIT.YOUR-DOMAIN.COM                 "
echo "#/*                                                                                                                    "
echo "# https://github.com/cockpit-project/cockpit/wiki/Cockpit-with-LetsEncrypt                                             "
echo "# cockpit configuration                                                                                                "
echo "# Create /etc/letsencrypt/deploy/update_cockpit_certificate.sh and replace your domain:                                "
sudo mkdir -p /etc/letsencrypt/deploy/
sudo touch /etc/letsencrypt/deploy/update_certificate.sh
sudo chmod a+x /etc/letsencrypt/deploy/update_certificate.sh
echo "# Add the following:                                                                                                    "
echo "#!/bin/bash                                                                                                             " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "  DOMAIN=COCKPIT.YOUR-DOMAIN.COM                                                                                        " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "#                                                                                                                       " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "# Copy cert for cockpit                                                                                                 " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "  sudo install -m 644 /etc/letsencrypt/live/\$DOMAIN/fullchain.pem /etc/cockpit/ws-certs.d/1-letsencrypt.cert           " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "  sudo install -m 640 -g cockpit-ws /etc/letsencrypt/live/\$DOMAIN/privkey.pem /etc/cockpit/ws-certs.d/1-letsencrypt.key" | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "#                                                                                                                       " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "# force a restart to pick up new certificate; this will interrupt existing sessions!                                    " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "# if you don't do this, cockpit.service will idle-timeout a minute ,after the last session closed                       " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "  sudo systemctl stop cockpit.service                                                                                   " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "#                                                                                                                       " | sudo tee -a /etc/letsencrypt/deploy/update_certificate.sh
echo "# After that, ensure that the script is executable:                                                                     "
echo "#                                                                                                                       "
echo "# chmod a+x /etc/letsencrypt/deploy/update_cockpit_certificate.sh                                                       "
echo "#*/                                                                                                                     "


# 0 3 * * * certbot certonly --standalone -n -d idoe-dev.app.idoe.tsscloudservices.dev --pre-hook "docker stop proxy" --post-hook "cp /etc/letsencrypt/live/idoe-dev.app.idoe.tsscloudservices.dev/fullchain.pem /opt/vars/nginx/crt/dev/; cp /etc/letsencrypt/live/idoe-dev.app.idoe.tsscloudservices.dev/privkey.pem /opt/vars/nginx/key/dev; docker start proxy"