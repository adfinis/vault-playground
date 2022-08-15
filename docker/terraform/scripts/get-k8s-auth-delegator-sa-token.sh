#!/bin/sh

# Set K3s server
sed -i "s/127.0.0.1/k3s-server.$1/g" /root/.kube/config

# Get Token Reviewer JWT
TOKEN=$(
  kubectl exec -it daemonset.apps/vault-csi-provider -n vault-csi-provider -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
)
jq -n --arg token "$TOKEN" '{"token":$token}'
