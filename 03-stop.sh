#!/bin/bash

# get container runntime
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
# the .env file will overwrite the environment variables
test -f .env && source .env

# stop containers
$CONTAINER_RUNTIME-compose down
