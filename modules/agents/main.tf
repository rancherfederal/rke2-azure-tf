locals {
  name = "${var.cluster_data.name}-${var.name}"

  ccm_tags = {
    "kubernetes.io_cluster_${var.cluster_data.name}" = "owned",
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

#
# Agent Nodepool
#
module "init" {
  source = "../custom_data"

  server_url = var.cluster_data.server_url
  vault_url = var.cluster_data.token.vault_url
  token_secret = var.cluster_data.token.token_secret

  config = ""
  pre_userdata = ""
  post_userdata = ""
  ccm = false

  agent = true
}

data "template_cloudinit_config" "init" {
  base64_encode = true

  part {
    filename = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/../common/download.sh", {
      rke2_version = var.rke2_version
      type = "agent"
    })
  }

  part {
    filename = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content = module.init.templated
  }
}

module "agents" {
  source = "../nodepool"

  name = "${local.name}-agent"

  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_id = var.virtual_network_id
  subnet_id = var.subnet_id

  admin_username = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  instances = var.instances
  assign_public_ips = var.assign_public_ips
  vm_size = var.vm_size
  source_image_reference = var.source_image_reference

  identity_ids = [var.cluster_data.cluster_identity_id]
  custom_data = data.template_cloudinit_config.init.rendered

  tags = merge({
    "Role" = "agent",
  }, local.ccm_tags, var.tags)

}