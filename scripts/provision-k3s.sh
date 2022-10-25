#!/usr/bin/env bash

# set -o errexit
set -o nounset
# set -o xtrace

#load the environment variables
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
CONTAINER_DOMAIN=${CONTAINER_DOMAIN:-docker}

test -f .env && source .env


# Use kubeconfig of the k3s container
export KUBECONFIG=$PWD/docker/k3s/output/kubeconfig.yaml

# Define variables related to the Vault CSI provider
VAULT_CSI_PROVIDER_NAMESPACE=vault-csi-provider
VAULT_KUBERNETES_AUTH_ROLE_NAME=kv-r

# Define variables for the test application/Pod
APP_NAMESPACE=vault-app
APP_SERVICEACCOUNT=vault-kv
# Define variables regarding the secret for the test Pod
SECRETPROVIDERCLASS_NAME=vault-secret
VAULT_ADDR="http://vault.${CONTAINER_DOMAIN}:8200"

# Patch CoreDNS to resolve the Vault Docker container name
# https://coredns.io/2017/06/08/how-queries-are-processed-in-coredns
VAULT_IP=$(${CONTAINER_RUNTIME} inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' vault)
kubectl patch configmap/coredns -n kube-system --patch "$(cat <<EOF
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        file /etc/coredns/identity.db ${CONTAINER_DOMAIN} 
        hosts /etc/coredns/NodeHosts {
          ttl 60
          reload 15s
          fallthrough
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
  identity.db: |
    ${CONTAINER_DOMAIN}.               IN      SOA     ns.${CONTAINER_DOMAIN}. hostmaster.${CONTAINER_DOMAIN}. 2021102901 7200 3600 1209600 3600
    vault.${CONTAINER_DOMAIN}.         IN      A       $VAULT_IP
EOF
)"

kubectl patch deployment/coredns -n kube-system --patch "$(cat <<EOF
spec:
  template:
    spec:
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
            - key: identity.db
              path: identity.db
            - key: NodeHosts
              path: NodeHosts
EOF
)"

# Instal Kubernetes CSI Driver
# https://secrets-store-csi-driver.sigs.k8s.io
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system

# Create Vault CSI Provider namespace
kubectl create ns $VAULT_CSI_PROVIDER_NAMESPACE

# Install Vault CSI Provider
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n $VAULT_CSI_PROVIDER_NAMESPACE \
  --set="injector.enabled=false" \
  --set="server.enabled=false" \
  --set="csi.enabled=true" \
  --set="server.serviceAccount.create=false" \
  --set="server.serviceAccount.name=vault-csi-provider"

# Create application namespace
kubectl create ns $APP_NAMESPACE

# Create ServiceAccount in the app namespace
kubectl create sa $APP_SERVICEACCOUNT -n $APP_NAMESPACE

# Deploy SecretProviderClass in the namespace of the application
cat <<EOF | kubectl apply -n $APP_NAMESPACE -f -
---
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: $SECRETPROVIDERCLASS_NAME
spec:
  parameters:
    objects: |
      - objectName: "password"
        secretPath: "tenant/kv/data/foo-secret?version=1"
        secretKey: "password"
    roleName: $VAULT_KUBERNETES_AUTH_ROLE_NAME
    vaultAddress: $VAULT_ADDR
  provider: vault
EOF

sleep 5;

# Deploy test app inside the namespace using ServiceAccount
cat <<EOF | kubectl apply -n $APP_NAMESPACE -f -
---
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  serviceAccountName: $APP_SERVICEACCOUNT
  containers:
  - image: busybox:latest
    command: ["/bin/sh"]
    args: ["-c", "while true; do cat /mnt/secrets-store/password; sleep 5; done"]
    imagePullPolicy: IfNotPresent
    name: test-pod
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: $SECRETPROVIDERCLASS_NAME
EOF
