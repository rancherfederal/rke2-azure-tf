terraform {
  required_providers {
    azurerm = {
      version = "~>3.38.0"
      source  = "hashicorp/azurerm"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>3.1.0"
    }
  }
}

locals {
  tags = {
    "Environment" = var.cluster_name,
    "Terraform"   = "true",
  }
  network_details     = regex("^(?P<vnet_id>\\/subscriptions\\/(?P<subscription>[^\\/]*)\\/resourceGroups\\/(?P<resource_group>[^\\/]*)\\/providers\\/Microsoft\\.Network\\/virtualNetworks\\/(?P<vnet>[^\\/]*))\\/subnets\\/(?P<subnet>[^\\/]*)$", var.subnet_id)
  resource_group_name = length(var.resource_group_name) > 0 ? var.resource_group_name : local.network_details.resource_group
}


module "rke2_cluster" {
  source              = "./modules/rke2-cluster"
  cluster_name        = var.cluster_name
  resource_group_name = local.resource_group_name
  vnet_id             = local.network_details.vnet_id
  subnet_id           = var.subnet_id
  vnet_name           = local.network_details.vnet
  subnet_name         = local.network_details.subnet
  cloud               = var.cloud
  tags                = local.tags

  server_public_ip       = var.server_public_ip
  server_open_ssh_public = var.server_open_ssh_public
  vm_size                = var.vm_size
  agent_vm_size          = var.agent_vm_size
  server_vm_size         = var.server_vm_size
  server_instance_count  = var.server_instance_count
  agent_instance_count   = var.agent_instance_count
}
