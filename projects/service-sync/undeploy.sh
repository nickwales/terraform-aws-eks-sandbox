#!/usr/bin/env bash

cluster_name=$(cat terraform.tfstate | jq -r .outputs.cluster_name.value)
region=$(cat terraform.tfstate | jq -r .outputs.region.value)


echo "#### Deploying Consul ####"
aws eks update-kubeconfig --region ${region} --name ${cluster_name}
helm uninstall consul hashicorp/consul --namespace consul

sleep 30

echo "#### Delete web apps ####"
kubectl delete -f apps/web.yaml -n frontend
kubectl delete -f apps/middleware.yaml -n middleware
kubectl delete -f apps/database.yaml -n backend

echo "#### Create namespaces ####"
kubectl delete namespace frontend
kubectl delete namespace database
kubectl delete namespace middleware
kubectl delete namespace consul

terraform destroy -auto-approve