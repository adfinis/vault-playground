#!/bin/bash

# get container runntime domain
CONTAINER_DOMAIN=${CONTAINER_DOMAIN:-docker}
test -f .env && source .env

# backup the hosts file
mkdir -p backup
cp /etc/hosts backup/hosts

# cleanup the hosts file
sudo sed -i '/### vault playground start ###/,/### vault playground end ###/d' /etc/hosts 


echo -e "### vault playground start ###" | sudo tee -a /etc/hosts
echo -e "#the cleanup script will delete everything between this tags" | sudo tee -a /etc/hosts


echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} ipa.${CONTAINER_DOMAIN}{{end}}" ipa) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} keycloak.${CONTAINER_DOMAIN}{{end}}" keycloak) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} vault.${CONTAINER_DOMAIN}{{end}}" vault) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} k3s-server.${CONTAINER_DOMAIN}{{end}}" k3s-server) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} grafana.${CONTAINER_DOMAIN}{{end}}" grafana) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} prometheus.${CONTAINER_DOMAIN}{{end}}" prometheus) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} es.${CONTAINER_DOMAIN}{{end}}" es) | sudo tee -a /etc/hosts
echo -e $(sudo -E ${CONTAINER_RUNTIME} inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}} kibana.${CONTAINER_DOMAIN}{{end}}" kibana) | sudo tee -a /etc/hosts

echo -e "### vault playground end ###" | sudo tee -a /etc/hosts
