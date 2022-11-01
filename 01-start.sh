#!/bin/bash

# get container runntime
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
# the .env file will overwrite the environment variables
test -f .env && source .env


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

# run containers
$CONTAINER_RUNTIME-compose up -d