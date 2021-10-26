#!/bin/bash

if [[ ! -f terraform.tfstate ]]; then
  echo "Unable to find terraform.tfstate please run from the directory you ran terraform apply"
  exit 1
fi

if [[ "$0" = "$BASH_SOURCE" ]]; then
  echo "Please source this script. Do not execute."
  exit 1
fi

DIRECTORY=$(dirname $0)

KV_NAME=${1:-$(terraform output -raw kv_name)}
FILE=$(realpath rke2.kubeconfig)

echo "Fetching kubeconfig from KeyVault $KV_NAME"
az keyvault secret show --name kubeconfig --vault-name $KV_NAME -o json | jq -r '.value' > $FILE

if [ $? -eq 0 ]; then
  echo "Download successful. Setting KUBECONFIG to $FILE"
  export KUBECONFIG=$FILE
fi
