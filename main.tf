locals {
  # Create a unique cluster name we'll prefix to all resources created and ensure it's lowercase
  uname = lower("${var.cluster_name}-${random_string.uid.result}")

  ccm_tags = {
    "kubernetes.io_cluster_${local.uname}" = "owned"
  }
}

/* data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
} */

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
  source = "./modules/statestore"

  name                = local.uname
  resource_group_name = var.resource_group_name
  location            = var.location

  token            = random_password.token.result
  reader_object_id = azurerm_user_assigned_identity.cluster.principal_id
}

#
# Server Identity
#
//resource "azurerm_role_definition" "server" {
//  name = "${local.uname}-server"
//  scope = data.azurerm_resource_group.rg.id
//
//  permissions {
//    actions = [
//      // Required to create, delete or update LoadBalancer for LoadBalancer service
//      "Microsoft.Network/loadBalancers/delete",
//      "Microsoft.Network/loadBalancers/read",
//      "Microsoft.Network/loadBalancers/write",
//
//      // Required to allow query, create or delete public IPs for LoadBalancer service
//      "Microsoft.Network/publicIPAddresses/delete",
//      "Microsoft.Network/publicIPAddresses/read",
//      "Microsoft.Network/publicIPAddresses/write",
//
//      // Required if public IPs from another resource group are used for LoadBalancer service
//      // This is because of the linked access check when adding the public IP to LB frontendIPConfiguration
//      "Microsoft.Network/publicIPAddresses/join/action",
//
//      // Required to create or delete security rules for LoadBalancer service
//      "Microsoft.Network/networkSecurityGroups/read",
//      "Microsoft.Network/networkSecurityGroups/write",
//
//      // Required to create, delete or update AzureDisks
//      "Microsoft.Compute/disks/delete",
//      "Microsoft.Compute/disks/read",
//      "Microsoft.Compute/disks/write",
//      "Microsoft.Compute/locations/DiskOperations/read",
//
//      // Required to create, update or delete storage accounts for AzureFile or AzureDisk
//      "Microsoft.Storage/storageAccounts/delete",
//      "Microsoft.Storage/storageAccounts/listKeys/action",
//      "Microsoft.Storage/storageAccounts/read",
//      "Microsoft.Storage/storageAccounts/write",
//      "Microsoft.Storage/operations/read",
//
//      // Required to create, delete or update routeTables and routes for nodes
//      "Microsoft.Network/routeTables/read",
//      "Microsoft.Network/routeTables/routes/delete",
//      "Microsoft.Network/routeTables/routes/read",
//      "Microsoft.Network/routeTables/routes/write",
//      "Microsoft.Network/routeTables/write",
//
//      // Required to query information for VM (e.g. zones, faultdomain, size and data disks)
//      "Microsoft.Compute/virtualMachines/read",
//
//      // Required to attach AzureDisks to VM
//      "Microsoft.Compute/virtualMachines/write",
//
//      // Required to query information for vmssVM (e.g. zones, faultdomain, size and data disks)
//      "Microsoft.Compute/virtualMachineScaleSets/read",
//      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
//      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/instanceView/read",
//
//      // Required to add VM to LoadBalancer backendAddressPools
//      "Microsoft.Network/networkInterfaces/write",
//
//      // Required to add vmss to LoadBalancer backendAddressPools
//      "Microsoft.Compute/virtualMachineScaleSets/write",
//
//      // Required to attach AzureDisks and add vmssVM to LB
//      "Microsoft.Compute/virtualMachineScaleSets/virtualmachines/write",
//
//      // Required to upgrade VMSS models to latest for all instances
//      // only needed for Kubernetes 1.11.0-1.11.9, 1.12.0-1.12.8, 1.13.0-1.13.5, 1.14.0-1.14.1
//      "Microsoft.Compute/virtualMachineScaleSets/manualupgrade/action",
//
//      // Required to query internal IPs and loadBalancerBackendAddressPools for VM
//      "Microsoft.Network/networkInterfaces/read",
//
//      // Required to query internal IPs and loadBalancerBackendAddressPools for vmssVM
//      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/read",
//
//      // Required to get public IPs for vmssVM
//      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/ipconfigurations/publicipaddresses/read",
//
//      // Required to check whether subnet existing for ILB in another resource group
//      "Microsoft.Network/virtualNetworks/read",
//      "Microsoft.Network/virtualNetworks/subnets/read",
//
//      // Required to create, update or delete snapshots for AzureDisk
//      "Microsoft.Compute/snapshots/delete",
//      "Microsoft.Compute/snapshots/read",
//      "Microsoft.Compute/snapshots/write",
//
//      // Required to get vm sizes for getting AzureDisk volume limit
//      "Microsoft.Compute/locations/vmSizes/read",
//      "Microsoft.Compute/locations/operations/read",
//    ]
//
//    not_actions = []
//  }
//
//  assignable_scopes = [
//    data.azurerm_resource_group.rg.id,
//  ]
//}

//resource "azurerm_role_assignment" "server" {
//  scope = data.azurerm_resource_group.rg.id
//  principal_id = azurerm_user_assigned_identity.server.principal_id
//  role_definition_id = azurerm_role_definition.server.role_definition_id
//}
//
//resource "azurerm_user_assigned_identity" "server" {
//  name = "${local.uname}-server"
//
//  resource_group_name = data.azurerm_resource_group.rg.name
//  location = data.azurerm_resource_group.rg.location
//
//  tags = merge({}, var.tags)
//}

resource "azurerm_user_assigned_identity" "cluster" {
  name = "${local.uname}-cluster"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge({}, var.tags)
}

resource "azurerm_role_assignment" "cluster_vault" {
  scope                = var.resource_group_id
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  role_definition_name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "cluster_reader" {
  scope                = module.servers.scale_set_id
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  role_definition_name = "Reader"
}

#
# Server Network Security Group
#
resource "azurerm_network_security_group" "server" {
  name = "${local.uname}-rke2-server-nsg"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge({}, var.tags)
}

resource "azurerm_network_security_rule" "server_cp" {
  name                        = "${local.uname}-rke2-server-controlplane"
  network_security_group_name = azurerm_network_security_group.server.name
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name

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
  resource_group_name         = var.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "9345"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Default vnet behavior for azure, but include anyways?
//resource "azurerm_network_security_rule" "vnet" {
//  name = "${local.uname}-rke2-self"
//  network_security_group_name = module.servers.network_security_group_name
//  access = "Allow"
//  direction = "Inbound"
//  priority = 1001
//  protocol = "*"
//  resource_group_name = data.azurerm_resource_group.rg.name
//
//  source_port_range = "*"
//  destination_port_range = "*"
//  source_address_prefix = "VirtualNetwork"
//  destination_address_prefix = "VirtualNetwork"
//}

# Default outbound behavior for azure, but include anyways?
//resource "azurerm_network_security_rule" "server_outbound" {
//  name = "${local.uname}-rke2-server-outbound"
//  network_security_group_name = module.servers.network_security_group_name
//  access = "Allow"
//  direction = "Outbound"
//  priority = 101
//  protocol = "*"
//  resource_group_name = data.azurerm_resource_group.rg.name
//
//  source_port_range = "*"
//  destination_port_range = "*"
//  source_address_prefix = "*"
//  destination_address_prefix = "*"
//}

#
# Server Nodepool
#
module "init" {
  source = "./modules/custom_data"

  server_url   = module.cp_lb.lb_url
  vault_url    = module.statestore.vault_url
  token_secret = module.statestore.token_secret_name

  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm

  agent = false
}

data "template_cloudinit_config" "init" {
  base64_encode = true

  part {
    filename     = "00_download.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/modules/common/download.sh", {
      rke2_version = var.rke2_version
      type         = "server"
    })
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init.templated
  }
}

module "cp_lb" {
  source = "./modules/lb"

  name                = local.uname
  resource_group_name = var.resource_group_name

  subnet_id                     = var.subnet_id
  private_ip_address            = var.controlplane_loadbalancer_private_ip_address
  private_ip_address_allocation = var.controlplane_loadbalancer_private_ip_address_allocation

  tags = merge({}, var.tags)
}

module "servers" {
  source = "./modules/nodepool"

  name = "${local.uname}-server"

  resource_group_name = var.resource_group_name
  virtual_network_id  = var.virtual_network_id
  subnet_id           = var.subnet_id

  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  vm_size                       = var.vm_size
  instances                     = var.servers
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
  nsg_id                 = azurerm_network_security_group.server.id

  health_probe_id                        = module.cp_lb.controlplane_probe_id
  load_balancer_backend_address_pool_ids = [module.cp_lb.backend_pool_id]

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