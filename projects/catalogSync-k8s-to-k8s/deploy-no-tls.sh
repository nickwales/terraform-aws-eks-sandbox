#!/bin/sh

# Setup kubectl
aws eks update-kubeconfig --name nEKS0 --region us-east-1 --alias eks0
aws eks update-kubeconfig --name nEKS1 --region us-east-1 --alias eks1

kubectl config use-context eks0
kubectl create namespace consul

consul-k8s install -auto-approve -f dc1-no-tls.yaml

sleep 30

server_addr=$(kubectl get svc -n consul consul-expose-servers -o json | jq -r '.status.loadBalancer.ingress[].hostname')
echo $server_addr

kubectl config use-context eks1

consul-k8s install -auto-approve -f catalogSync-no-tls.yaml --set externalServers.hosts={$server_addr} -timeout=5m

/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --ignore-certificate-errors "https://${server_addr}:8500"

kubectl apply -f apps/database.yaml





