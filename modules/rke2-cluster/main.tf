locals {
  nodepool_nsgs = [module.rke2.network_security_group_name]
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "k8s" {
  name = "${var.cluster_name}-k8s-nsg"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  tags = merge({}, var.tags)
}

module "rke2" {
  source = "../rke2-server"

  cluster_name        = var.cluster_name
  resource_group_name = var.resource_group_name

  virtual_network_id   = var.vnet_id
  subnet_id            = var.subnet_id
  virtual_network_name = var.vnet_name
  subnet_name          = var.subnet_name
  k8s_nsg_name         = azurerm_network_security_group.k8s.name

  admin_ssh_public_key = tls_private_key.default.public_key_openssh

  servers  = var.server_instance_count
  vm_size  = length(var.server_vm_size) > 0 ? var.server_vm_size : var.vm_size
  priority = "Regular" #"Spot"

  enable_ccm      = true
  cloud           = var.cloud
  public_ip       = var.server_public_ip
  open_ssh_public = var.server_open_ssh_public

  # OS tuning 
  pre_userdata = <<EOF
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
EOF

  tags = var.tags
}

module "generic_agents" {
  source       = "../rke2-agents"
  cluster_data = module.rke2.cluster_data

  name                = "generic"
  resource_group_name = var.resource_group_name

  virtual_network_id   = var.vnet_id
  subnet_id            = var.subnet_id
  virtual_network_name = var.vnet_name
  subnet_name          = var.subnet_name
  k8s_nsg_name         = azurerm_network_security_group.k8s.name

  admin_ssh_public_key = tls_private_key.default.public_key_openssh

  instances = var.agent_instance_count
  vm_size   = length(var.agent_vm_size) > 0 ? var.agent_vm_size : var.vm_size
  priority  = "Regular" #"Spot"
  cloud     = var.cloud

  # OS tuning 
  pre_userdata = <<EOF
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
EOF

  tags = var.tags
}

resource "azurerm_key_vault_secret" "node_key" {
  name         = "node-key"
  value        = tls_private_key.default.private_key_pem
  key_vault_id = module.rke2.cluster_data.token.vault_id
}

resource "local_file" "node_private_key" {
  content  = tls_private_key.default.private_key_pem
  filename = ".ssh/rk2_id_rsa"
}

resource "local_file" "node_public_key" {
  content  = tls_private_key.default.public_key_openssh
  filename = ".ssh/rk2_id_rsa.pub"
}


# Dev/Example settings only

# Open up ssh on all the nodepools
resource "azurerm_network_security_rule" "ssh" {
  count = length(local.nodepool_nsgs)

  name                        = "${var.cluster_name}-ssh"
  access                      = "Allow"
  direction                   = "Inbound"
  network_security_group_name = local.nodepool_nsgs[count.index]
  priority                    = 201
  protocol                    = "Tcp"
  resource_group_name         = var.resource_group_name

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "22"
}
