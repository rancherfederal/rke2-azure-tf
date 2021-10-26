#!/bin/bash

set -e

if [[ ! -f terraform.tfstate ]]; then
  echo "Unable to find terraform.tfstate please run from the directory you ran terraform apply"
  exit 1
fi

FILE_NAME="rke2.priv_key"
USERNAME="rke2"

KV_NAME=${1:-$(terraform output -raw kv_name)}
if [[ $1 != "" ]]; then
  RG=${1%-*}
  SERVER_URL=$(az network public-ip show -g $RG -n $1-pip --query "ipAddress" -o tsv)
else
  SERVER_URL=$(terraform output -json rke2_cluster | jq -r '.server_url')
fi

az keyvault secret show --name node-key --vault-name $KV_NAME | jq -r '.value' > $FILE_NAME
[[ $# != 0 ]] && { echo "Failed to fetch node-key secret from KeyVault: $KV_NAME"; exit 1; }
chmod 600 $FILE_NAME

echo "Connect to the first server with the following command:"
echo "  ssh ${USERNAME}@${SERVER_URL} -p 5000 -i $FILE_NAME"
echo "For each server in the cluster increase the port by 1, e.g. 5001, 5002"
