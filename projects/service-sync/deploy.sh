#!/usr/bin/env bash

terraform -chdir=terraform apply

cluster_name=$(cat terraform.tfstate | jq -r .outputs.cluster_name.value)
region=$(cat terraform.tfstate | jq -r .outputs.region.value)



echo "#### Update kubectl ####"
aws eks update-kubeconfig --region ${region} --name ${cluster_name}


## Deploy Nginx Ingress Controller
# https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/

helm install my-release oci://ghcr.io/nginxinc/charts/nginx-ingress --version 0.18.0

## Deploy Consul
echo "#### Deploying license ####"
secret=$(cat consul.hclic)
kubectl create namespace consul
kubectl create secret -n consul generic consul-ent-license --from-literal="key=${secret}"

#kubectl create secret -n consul generic consul-ca-cert --from-file='tls.crt=./certs/consul-agent-ca.pem'
#kubectl create secret -n consul generic consul-ca-key --from-file='tls.key=./certs/consul-agent-ca-key.pem'

kubectl create secret -n consul generic consul-ca-key --from-file='tls.key=./certs/dc1-client-consul-0-key.pem'
kubectl create secret -n consul generic consul-ca-cert --from-file='tls.crt=./certs/dc1-client-consul-0.pem'

#helm install consul hashicorp/consul --create-namespace --namespace consul --values helm/values-ent.yaml

consul-k8s install -f helm/external_server.yaml

sleep 30

export CONSUL_HTTP_ADDR=http://$(kubectl -n consul get svc consul-ui -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
export CONSUL_HTTP_TOKEN=$(kubectl -n consul get secret consul-bootstrap-acl-token  -o json | jq '.data | map_values(@base64d)' | jq -r .token)
export CONSUL_HTTP_SSL_VERIFY=false
echo "Your Consul cluster is available at:"
echo $CONSUL_HTTP_ADDR
echo "Your Consul ACL token is:"
echo $CONSUL_HTTP_TOKEN

### Works on OSX

open $CONSUL_HTTP_ADDR


### Create Namespaces ###

consul namespace create -name frontend
consul namespace create -name database
consul namespace create -name middleware
consul namespace create -name backend

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
kubectl create namespace backend

echo "#### Deploy web app to frontend namespace ####"
kubectl apply -f apps/web.yaml -n frontend
kubectl apply -f apps/middleware.yaml -n middleware
kubectl apply -f apps/database.yaml -n database

## "Sleep while we wait for apps to be deployed"
sleep 20

echo "#### Get the consul catalog ####"
consul catalog services

echo "Notice the middleware is missing because we didn't include it in our list of namespaces to sync"
echo "Update line 27 in helm/values.yaml to enable and run:"
echo "helm upgrade consul hashicorp/consul --namespace consul --values helm/values.yaml


## Update CoreDNS ConfigMap

kubectl -n kube-system edit configmap coredns

# 172.20.145.21

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
      forward . 172.20.59.117
    }
"


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
      forward . 172.20.94.195
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"Corefile":".:53 {\n    errors\n    health\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n      pods insecure\n      fallthrough in-addr.arpa ip6.arpa\n    }\n    prometheus :9153\n    forward . /etc/resolv.conf\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"labels":{"eks.amazonaws.com/component":"coredns","k8s-app":"kube-dns"},"name":"coredns","namespace":"kube-system"}}
  creationTimestamp: "2023-07-13T14:12:56Z"
  labels:
    eks.amazonaws.com/component: coredns
    k8s-app: kube-dns
  name: coredns
  namespace: kube-system
  resourceVersion: "281"
  uid: df6208ec-24eb-4cc5-be60-a579ce9d4e74


### Nginx Deploy
helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --version 0.18.0


### Create a load balancer for the KubeDNS service

kubectl apply -f apps/consul_dns.yaml

