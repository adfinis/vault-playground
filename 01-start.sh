#!/bin/bash

# message
MESSAGE="This is a development environment and should not be used in production!"
RED='\033[0;31m'
NC='\033[0m' 

# check if cowsay is installed
if ! command -v cowsay &> /dev/null
then
    echo -e "${RED}${MESSAGE}${NC}"
else
    echo -e "${RED}$(cowsay -f stegosaurus ${MESSAGE})${NC}"
fi


# get container runntime
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
# the .env file will overwrite the environment variables
test -f .env && source .env


#adjust the docker-compose.yml file and vault config
if [ "$CONTAINER_RUNTIME" == "podman" ]; then
    sudo sed -i 's/statsd_address =.*$/statsd_address = '\"host.containers.internal:8125\"'/g' ./docker/vault/config/statsd-telemetry.hcl
    sed -i 's/extra_hosts:.*$/# extra_hosts:/g' docker-compose.yaml
    sed -i 's/  - host.docker.internal:host-gateway.*$/#  - host.docker.internal:host-gateway/g' docker-compose.yaml
fi
else if [ "$CONTAINER_RUNTIME" == "docker" ]; then
    sudo sed -i 's/statsd_address =.*$/statsd_address = '\"host.docker.internal:8125\"'/g' ./docker/vault/config/statsd-telemetry.hcl
    sed -i 's/# extra_hosts:.*$/extra_hosts:/g' docker-compose.yaml
    sed -i 's/#  - host.docker.internal:host-gateway.*$/  - host.docker.internal:host-gateway/g' docker-compose.yaml
fi


# manually build the terraform image
if [ "$CONTAINER_RUNTIME" == "podman" ]; then
    sudo podman build --network=host ./terraform-dockerfile
fi



# run containers
$CONTAINER_RUNTIME-compose up -d