#!/usr/bin/env bash

cluster_name=$(cat terraform.tfstate | jq -r .outputs.cluster_name.value)
region=$(cat terraform.tfstate | jq -r .outputs.region.value)


echo "#### Deploying Consul ####"
aws eks update-kubeconfig --region ${region} --name ${cluster_name}
helm install consul hashicorp/consul --create-namespace --namespace consul --values helm/values.yaml

sleep 30

export CONSUL_HTTP_ADDR=$(kubectl -n consul get svc consul-ui -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret consul-bootstrap-acl-token  -o json | jq '.data | map_values(@base64d)' | jq -r .token)

echo "Your Consul cluster is available at:"
echo $CONSUL_HTTP_ADDR
echo "Your Consul ACL token is:"
echo $CONSUL_HTTP_TOKEN

echo "\n\nExport these values to your shell with: "
echo "export CONSUL_HTTP_ADDR=https://${CONSUL_HTTP_ADDR} CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN} CONSUL_HTTP_SSL_VERIFY=false"

### Setting up Consul DNS ###
export CONSUL_DNS_IP=$(kubectl -n consul get svc consul-dns --output jsonpath='{.spec.clusterIP}')
cat <<EOF | kubectl apply --filename -
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"consul": ["$CONSUL_DNS_IP"]}
EOF

echo "#### Create namespaces ####"
kubectl create namespace frontend
kubectl create namespace database
kubectl create namespace middleware

echo "#### Deploy web app to frontend namespace ####"
kubectl apply -f apps/web.yaml -n frontend
kubectl apply -f apps/middleware.yaml -n middleware
kubectl apply -f apps/database.yaml -n backend

## "Sleep while we wait for apps to be deployed"
sleep 20

echo "#### Get the consul catalog ####"
consul catalog services

echo "Notice the middleware is missing because we didn't include it in our list of namespaces to sync"
echo "Update line 27 in helm/values.yaml to enable and run:"
echo "helm upgrade consul hashicorp/consul --namespace consul --values helm/values.yaml



echo "
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    consul:53 {
      errors
      cache 30
      forward . 172.20.35.24
    }
"