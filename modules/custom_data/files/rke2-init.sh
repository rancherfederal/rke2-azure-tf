#!/bin/bash

export TYPE="${type}"
export CCM="${ccm}"
export CLOUD="${cloud}"

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
# Additional user defined configuration
${config}
EOF
}

append_config() {
  echo "$1" >> "/etc/rancher/rke2/config.yaml"
}

get_azure_domain() {
  if [ "$CLOUD" = "AzureUSGovernmentCloud" ]; then
    echo 'usgovcloudapi.net'
  else
    echo 'azure.com'
  fi
}

get_azure_vault() {
  if [ "$CLOUD" = "AzureUSGovernmentCloud" ]; then
    echo 'usgovcloudapi.net'
  else
    echo 'azure.net'
  fi
}

# The most simple "leader election" you've ever seen in your life
elect_leader() {

  azure_domain=$(get_azure_domain)

  access_token=$(curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.$${azure_domain}" -H Metadata:true | jq -r ".access_token")

  read subscriptionId resourceGroupName virtualMachineScaleSetName < \
    <(echo $(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | jq -r ".compute | .subscriptionId, .resourceGroupName, .vmScaleSetName"))

  first=$(curl -s https://management.$${azure_domain}/subscriptions/$${subscriptionId}/resourceGroups/$${resourceGroupName}/providers/Microsoft.Compute/virtualMachineScaleSets/$${virtualMachineScaleSetName}/virtualMachines?api-version=2020-12-01 \
          -H "Authorization: Bearer $${access_token}" | jq -ej "[.value[]] | sort_by(.instanceId | tonumber) | .[0].properties.osProfile.computerName")

  
  if [ $(hostname) = $${first} ]; then
    SERVER_TYPE="leader"
    info "Electing as cluster leader"
  else
    info "Electing as joining server"
  fi
}

identify() {
  info "Identifying server type..."

  # Default to server
  SERVER_TYPE="server"

  supervisor_status=$(curl --max-time 5.0 --write-out '%%{http_code}' -sk --output /dev/null https://"${server_url}":9345/ping)

  if [ "$supervisor_status" -ne 200 ]; then
    info "API server unavailable, performing simple leader election"
    elect_leader
  else
    info "API server available, identifying as server joining existing cluster"
  fi
}

cp_wait() {
  while true; do
    supervisor_status=$(curl --max-time 5.0 --write-out '%%{http_code}' -sk --output /dev/null https://"${server_url}":9345/ping)
    if [ "$supervisor_status" -eq 200 ]; then
      info "Cluster is ready"

      # Let things settle down for a bit, without this HA cluster creation is very unreliable
      sleep 10
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

fetch_token() {
  info "Fetching rke2 join token..."

  azure_vault=$(get_azure_vault)

  access_token=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.$${azure_vault}" -H Metadata:true | jq -r ".access_token")
  token=$(curl '${vault_url}secrets/${token_secret}?api-version=2016-10-01' -H "Authorization: Bearer $${access_token}" | jq -r ".value")

  echo "token: $${token}" >> "/etc/rancher/rke2/config.yaml"
}

upload() {
  # Wait for kubeconfig to exist, then upload to secrets
  retries=10

  while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do
    sleep 10
    if [ "$retries" = 0 ]; then
      fatal "Failed to create kubeconfig"
    fi
    ((retries--))
  done

  azure_vault=$(get_azure_vault)

  access_token=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.$${azure_vault}" -H Metadata:true | jq -r ".access_token")

  curl -v -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $${access_token}" \
    "${vault_url}secrets/kubeconfig?api-version=7.1" \
    --data-binary @- << EOF
{
  "value": "$(sed "s/127.0.0.1/${server_url}/g" /etc/rancher/rke2/rke2.yaml)"
}
EOF
}

pre_userdata() {
  info "Beginning user defined pre userdata"
  ${pre_userdata}
  info "Beginning user defined pre userdata"
}

post_userdata() {
  info "Beginning user defined post userdata"
  ${post_userdata}
  info "Ending user defined post userdata"
}

{
  pre_userdata

  config
  fetch_token

  if [ "$CCM" = "true" ]; then
    append_config 'cloud-provider-name: azure'
    append_config 'cloud-provider-config: /etc/rancher/rke2/cloud.conf'
  fi

  # Config which is applied to both agent and server nodes
  append_config 'node-label: ${node_labels}'
  append_config 'node-taint: ${node_taints}'

  if [ "$TYPE" = "server" ]; then
    # Initialize server
    identify

    cat <<EOF >> "/etc/rancher/rke2/config.yaml"
tls-san:
  - ${server_url}
EOF

    if [ $SERVER_TYPE = "server" ]; then
      append_config 'server: https://${server_url}:9345'
      # Wait for cluster to exist, then init another server
      cp_wait
    fi

    # This attempts to stagger the times when servers try to join the cluster
    # We rely on the well ordered cardinal host names that VMSS will assign
    host=$(hostname)
    hostNum=$${host: -2}
    sleepTime=$(( hostNum * 80 ))
    info "Staggering process, waiting extra $sleepTime seconds before joining..."
    sleep $sleepTime

    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    export PATH=$PATH:/var/lib/rancher/rke2/bin

    # Upload kubeconfig to s3 bucket
    upload

  else
    append_config 'server: https://${server_url}:9345'

    # Default to agent
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
  fi

  post_userdata
}
