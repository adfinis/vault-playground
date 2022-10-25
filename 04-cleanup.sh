#!/bin/bash

read -p "Do you really want to delete vault-playground Docker data [y/N]? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Stopping and removing containers"
./03-stop.sh

# cleanup the docker data
sudo rm -rf docker/{ipa,k3s,keycloak-postgres,kibana,es}
sudo rm -rf docker/vault/data

read -p "Do you really want to cleanup Terraform state [y/N]? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# cleanup the Terraform state
sudo rm -rf docker/terraform/*.tfstate*
sudo rm -rf docker/terraform/.terraform.lock.hcl
sudo rm -rf docker/terraform/.terraform

# cleanup the hosts file
sudo sed -i '/### vault playground start ###/,/### vault playground end ###/d' /etc/hosts 
echo "If /etc/hosts file got cleanup incorrectly, please restore it from backup/hosts"
