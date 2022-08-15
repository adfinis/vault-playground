#!/bin/sh

CACERTS=$(curl -ks "https://k3s-server.$1:6443/cacerts")
jq -n --arg cacerts "$CACERTS" '{"cacerts":$cacerts}'
