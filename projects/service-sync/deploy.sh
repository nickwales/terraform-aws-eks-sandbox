#!/usr/bin/env bash

# Create certs
consul tls ca create
mkdir certs
mv *.pem certs/

terraform -chdir=terraform apply -auto-approve

cluster_name=$(cat terraform.tfstate | jq -r .outputs.cluster_name.value)
region=$(cat terraform.tfstate | jq -r .outputs.region.value)

echo "#### Update kubectl ####"
aws eks update-kubeconfig --region ${region} --name ${cluster_name}
