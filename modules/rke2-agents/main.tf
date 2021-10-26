locals {
  name = "${var.cluster_data.name}-${var.name}"

  ccm_tags = {
    "kubernetes.io_cluster_${var.cluster_data.name}" = "owned",
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

#
# Agent Nodepool
#
module "init" {
  source = "../custom_data"

  server_url   = var.cluster_data.server_url
  vault_url    = var.cluster_data.token.vault_url
  token_secret = var.cluster_data.token.token_secret

  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  # Has to be set to true on agents for Azure disk based PVCs to mount
  ccm         = true
  cloud       = var.cloud
  node_labels = "[\"failure-domain.beta.kubernetes.io/region=${data.azurerm_resource_group.rg.location}\"]"
  node_taints = "[]"

  agent = true
}

data "template_cloudinit_config" "init" {
  base64_encode = true

  part {
    filename     = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/../common/download.sh", {
      rke2_version = var.rke2_version
      type         = "agent"
    })
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init.templated
  }

  part {
    filename     = "azure-cloud.tpl"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          content     = "vm.max_map_count=262144\nsysctl -w fs.file-max=131072"
          path        = "/etc/sysctl.d/10-vm-map-count.conf"
          permissions = "5555"
        },
        {
          content = templatefile("${path.module}/../custom_data/files/azure-cloud.conf.template", {
            tenant_id                 = data.azurerm_client_config.current.tenant_id
            user_assigned_identity_id = var.cluster_data.cluster_identity_client_id
            subscription_id           = data.azurerm_client_config.current.subscription_id
            rg_name                   = data.azurerm_resource_group.rg.name
            location                  = data.azurerm_resource_group.rg.location
            subnet_name               = var.subnet_name
            virtual_network_name      = var.virtual_network_name
            nsg_name                  = var.k8s_nsg_name
            cloud                     = var.cloud
          })
          path        = "/etc/rancher/rke2/cloud.conf"
          permissions = "5555"
        }
      ]
    })
  }
}

resource "azurerm_network_security_group" "agent" {
  name = "${local.name}-agent-nsg"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  security_rule {
    name                       = "istio-http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "istio-https"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge({}, var.tags)
}

module "agents" {
  source = "../nodepool"

  name = "${local.name}-agent"

  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_id  = var.virtual_network_id
  subnet_id           = var.subnet_id

  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  vm_size                       = var.vm_size
  instances                     = var.instances
  overprovision                 = var.overprovision
  zones                         = var.zones
  zone_balance                  = var.zone_balance
  single_placement_group        = var.single_placement_group
  upgrade_mode                  = var.upgrade_mode
  priority                      = var.priority
  eviction_policy               = var.priority == "Spot" ? var.eviction_policy : null
  dns_servers                   = var.dns_servers
  enable_accelerated_networking = var.enable_accelerated_networking

  source_image_reference = var.source_image_reference
  assign_public_ips      = var.assign_public_ips
  nsg_id                 = azurerm_network_security_group.agent.id

  identity_ids = [var.cluster_data.cluster_identity_id]
  custom_data  = data.template_cloudinit_config.init.rendered

  os_disk_size_gb              = var.os_disk_size_gb
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_encryption_set_id    = var.os_disk_encryption_set_id

  additional_data_disks = var.additional_data_disks

  tags = merge({
    "Role" = "agent",
  }, local.ccm_tags, var.tags)
}
