# You need to run this script as root.
# DOMAIN
# ADMIN_PASSWORD
# IP

mkdir -p /root/onlyoffice


echo "docker run -i -t -d -p 10923:80 --restart=unless-stopped --name onlyoffice -e JWT_ENABLED='true' -e JWT_SECRET='$ADMIN_PASSWORD' onlyoffice/documentserver" > /root/onlyoffice/run.sh

bash /root/onlyoffice/run.sh

if [ $DOMAIN = "int.de" ] ; then
  docker exec onlyoffice sed -i 's/"rejectUnauthorized": true/"rejectUnauthorized": false/g' /etc/onlyoffice/documentserver/default.json
  docker exec onlyoffice echo "$IP cloud.$DOMAIN" >> /etc/hosts
  docker restart onlyoffice
fi

# Add the content of caddy_onlyoffice_entry.txt to /etc/caddy/Caddyfile
cat caddy_onlyoffice_entry.txt >> /etc/caddy/Caddyfile
sed -i "s/SED_DOMAIN/$DOMAIN/g" /etc/caddy/Caddyfile


# if $DOMAIN = "int.de" then uncomment #tls internal
if [ $DOMAIN = "int.de" ] ; then
  sed -i "s/#tls internal/tls internal/g" /etc/caddy/Caddyfile
fi

systemctl reload caddy



# Install in nextcloud the onlyoffice app
sudo -u www-data php /var/www/nextcloud/occ app:install onlyoffice

# Configure onlyoffice
sudo -u www-data php /var/www/nextcloud/occ config:app:set onlyoffice DocumentServerUrl --value="https://office.$DOMAIN/"
# Set the secret ($ADMIN_PASSWORD)
sudo -u www-data php /var/www/nextcloud/occ config:app:set onlyoffice jwt_secret --value="$ADMIN_PASSWORD"
# if $DOMAIN = "int.de" then deactivate the certificate verification
if [ $DOMAIN = "int.de" ] ; then
  sudo -u www-data php /var/www/nextcloud/occ config:app:set onlyoffice documentserver_verify_peer_off --value="true"
fi
# Disable the document preview
sudo -u www-data php /var/www/nextcloud/occ config:app:set onlyoffice preview --value="false"