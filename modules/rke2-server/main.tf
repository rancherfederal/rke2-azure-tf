locals {
  # Create a unique cluster name we'll prefix to all resources created and ensure it's lowercase
  uname = lower("${var.cluster_name}-${random_string.uid.result}")

  ccm_tags = {
    "kubernetes.io_cluster_${local.uname}" = "owned"
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "uid" {
  length  = 3
  special = false
  lower   = true
  upper   = false
  number  = true
}

resource "random_password" "token" {
  length  = 40
  special = false
}

module "statestore" {
  source = "../statestore"

  name                = local.uname
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  token            = random_password.token.result
  reader_object_id = azurerm_user_assigned_identity.cluster.principal_id
}

resource "azurerm_user_assigned_identity" "cluster" {
  name = "${local.uname}-cluster"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  tags = merge({}, var.tags)
}

resource "azurerm_role_assignment" "cluster_vault" {
  scope                = data.azurerm_resource_group.rg.id
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "cluster_reader" {
  scope                = module.servers.scale_set_id
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  role_definition_name = "Reader"
}


resource "azurerm_role_assignment" "role1" {
  scope                            = data.azurerm_resource_group.rg.id #module.servers.scale_set_id 
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.cluster.principal_id
  skip_service_principal_aad_check = true

}

resource "azurerm_role_assignment" "role2" {
  scope                            = data.azurerm_resource_group.rg.id #module.servers.scale_set_id 
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cluster.principal_id
  skip_service_principal_aad_check = true

}

#
# Server Network Security Group
#
resource "azurerm_network_security_group" "server" {
  name = "${local.uname}-rke2-server-nsg"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  tags = merge({}, var.tags)
}

resource "azurerm_network_security_rule" "server_cp" {
  name                        = "${local.uname}-rke2-server-controlplane"
  network_security_group_name = azurerm_network_security_group.server.name
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = data.azurerm_resource_group.rg.name

  source_port_range          = "*"
  destination_port_range     = "6443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "server_supervisor" {
  name                        = "${local.uname}-rke2-server-supervisor"
  network_security_group_name = azurerm_network_security_group.server.name
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = data.azurerm_resource_group.rg.name

  source_port_range          = "*"
  destination_port_range     = "9345"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

#
# Server Nodepool
#
module "init" {
  source = "../custom_data"

  server_url   = module.cp_lb.lb_url
  vault_url    = module.statestore.vault_url
  token_secret = module.statestore.token_secret_name

  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  node_labels   = "[]"
  node_taints   = "[\"CriticalAddonsOnly=true:NoExecute\"]"
  cloud         = var.cloud
  agent         = false
}

data "azurerm_client_config" "current" {}

data "template_cloudinit_config" "init" {
  base64_encode = true

  part {
    filename     = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/../common/download.sh", {
      rke2_version = var.rke2_version
      type         = "server"
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
            user_assigned_identity_id = azurerm_user_assigned_identity.cluster.client_id
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
        },
        {
          content     = templatefile("${path.module}/../custom_data/files/default-storageclass.yaml", {})
          path        = "/var/lib/rancher/rke2/server/manifests/default-storageclass.yaml"
          permissions = "5555"
        }
      ]
    })
  }
}

module "cp_lb" {
  source = "../lb"

  name                = local.uname
  resource_group_name = data.azurerm_resource_group.rg.name

  subnet_id                     = var.subnet_id
  private_ip_address            = var.controlplane_loadbalancer_private_ip_address
  private_ip_address_allocation = var.controlplane_loadbalancer_private_ip_address_allocation

  tags = merge({}, var.tags)

  type = var.public_ip ? "public" : "private"
}

module "servers" {
  source = "../nodepool"

  name = "${local.uname}-server"

  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_id  = var.virtual_network_id
  subnet_id           = var.subnet_id

  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  vm_size   = var.vm_size
  instances = var.servers
  # Forcing this to false, as the RKE2 bootstrap now relies on well ordered hostnames to stagger the join process
  overprovision                 = false
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
  nsg_id                 = azurerm_network_security_group.server.id

  health_probe_id                        = module.cp_lb.controlplane_probe_id
  load_balancer_backend_address_pool_ids = [module.cp_lb.backend_pool_id]
  load_balancer_inbound_nat_rules_ids    = var.open_ssh_public ? [module.cp_lb.azurerm_lb_nat_pool_ssh_id] : []

  identity_ids = [azurerm_user_assigned_identity.cluster.id]
  custom_data  = data.template_cloudinit_config.init.rendered

  enable_automatic_instance_repair       = var.enable_automatic_instance_repair
  automatic_instance_repair_grace_period = var.enable_automatic_instance_repair ? var.automatic_instance_repair_grace_period : null

  os_disk_size_gb              = var.os_disk_size_gb
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_encryption_set_id    = var.os_disk_encryption_set_id

  additional_data_disks = var.additional_data_disks

  tags = merge({
    "Role" = "server",
  }, local.ccm_tags, var.tags)

  # Fix bug with dependency upon resource deletions
  depends_on = [module.cp_lb]
}
