#!/bin/bash

# get container runntime
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}

# stop containers
$CONTAINER_RUNTIME-compose down
