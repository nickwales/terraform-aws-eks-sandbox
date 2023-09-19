#!/bin/sh

aws eks update-kubeconfig --name nEKS0 --region us-east-1 --alias eks0
aws eks update-kubeconfig --name nEKS1 --region us-east-1 --alias eks1

kubectl config use-context eks0

kubectl create namespace consul


kubectl create secret -n consul generic consul-agent-ca \
    --from-file='tls.crt=./certs/consul-agent-ca.pem'

kubectl create secret -n consul generic consul-agent-ca-key \
    --from-file='tls.key=./certs/consul-agent-ca-key.pem'

consul-k8s install -auto-approve -f dc1.yaml

sleep 60


server_addr=$(kubectl get svc -n consul consul-expose-servers -o json | jq -r '.status.loadBalancer.ingress[].hostname')
echo $server_addr



kubectl config use-context eks1
kubectl create namespace consul
kubectl create secret -n consul generic consul-agent-ca \
    --from-file='tls.crt=./certs/consul-agent-ca.pem'

kubectl create secret -n consul generic consul-agent-ca-key \
    --from-file='tls.key=./certs/consul-agent-ca-key.pem'

consul-k8s install -f catalogSync.yaml --set externalServers.hosts={$server_addr} -timeout=5m

/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --ignore-certificate-errors "https://${server_addr}:8501"

kubectl apply -f apps/database.yaml





