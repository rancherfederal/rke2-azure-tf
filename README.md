This project includes the Terraform configuration to deploy an RKE2 cluster in Azure.

# Notes

1. The terraform script does not work within Azure Cloudshell because of a Cloudshell/Terraform AzureRM provider [issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/7787).
1. A .devcontainer is provided with all dependencies installed. It is not required to be used.
1. It is expected that the cloud target has been set using az cloud set -name AzureUSGovernment and an az login and subscription setting has been performed.
1. The .tfvar cloud variable values are determined by the Kubernetes azure cloud provider which utilises the [go-autorest library](https://github.com/Azure/go-autorest/blob/v9.9.0/autorest/azure/environments.go#L29) which doesn't use Azure defined cloud names.

# Supported Azure regions

These regions were deployed and tested other regions might also work

1. USGovVirginia
1. USGovArizona

# Getting Started

1.  Start devcontainer in VScode or install prerequisites in your system. The devcontainer is in [.devcontainer](.devcontainer).

2. An example usage of this module can be found in the [quickstart](./examples/quickstart) folder

# Connecting to RKE2

This section assumes you have a publicly accessible cluster, i.e. you have set `server_public_ip` to true

A script is provided to download the kubeconfig file needed to access the cluster, from KeyVault to the local machine, it also sets KUBECONFIG to point to the new kubeconfig

```bash
source scripts/fetch-kubeconfig.sh
```

> **Note.** You must run this from the location where Terraform apply has been run and there is a terraform.tfstate file
> **Note.** You must source the script, also you may have to wait for a minute or two after deploying the cluster before the kubeconfig is ready

Now you can run kubectl commands against the cluster as normal, e.g. `kubectl get nodes` or `kubectl get pods -A` to see the status and health of the cluster.

# Smoke Tests

A set of simple smoke tests is provided to validate the cluster is healthy and can communicate with Azure

See [Smoke Tests for Bare Metal Kubernetes on Azure](./tests/README.md)

# SSH to Servers (Control Plane)

If you set `server_open_ssh_public` to true, then SSH will be allowed onto the server nodes, through the control plane load balancer. 

> Note. This is only recommended when troubleshooting RKE2 itself, and associated configuration such as the Azure cloud provider. For normal operation SSH access is not required.

This is done with a Azure Load Balancer NAT pool, the pool maps ports from 5000 onwards to port 22 on each of the instances, e.g.

- Port 5000 -> port 22 on instance 0
- Port 5001 -> port 22 on instance 1
- Port 5002 -> port 22 on instance 2
- etc

A script is provided that will download the SSH private key from KeyVault and tell you the public IP you need to use. The SSH username is `rke2`

```bash
./scripts/fetch-ssh-key.sh
```

> **Note.** You must run this from the location where Terraform apply has been run and there is a terraform.tfstate file

> **Note.** For reasons unknown sometimes the scale set takes some time to settle down, and even with a single instance, it might not be instance 0, it can be 1 or even 2, so try ports 5001 and 5002 if 5000 doesn't work