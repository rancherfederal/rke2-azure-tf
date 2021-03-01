provider "azurerm" {
  features {}
}

locals {
  name = "rke2-quickstart"
  tags = {
    "Environment" = local.name,
    "Terraform" = "true",
  }

  nodepool_nsgs = [module.rke2.network_security_group_name, module.generic_agents.network_security_group_name]
}

resource "azurerm_resource_group" "quickstart" {
  name = local.name
  location = "Central US"
}

resource "azurerm_virtual_network" "vnet" {
  name = "${local.name}-vnet"
  address_space = ["10.0.0.0/16"]

  resource_group_name = azurerm_resource_group.quickstart.name
  location = azurerm_resource_group.quickstart.location

  tags = local.tags
}

resource "azurerm_subnet" "snet" {
  name = "${local.name}-snet"

  resource_group_name = azurerm_resource_group.quickstart.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

module "rke2" {
  source = "../.."

  cluster_name = local.name
  resource_group_name = azurerm_resource_group.quickstart.name

  virtual_network_id = azurerm_virtual_network.vnet.id
  subnet_id = azurerm_subnet.snet.id

  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  servers = 3

  tags = local.tags

  depends_on = [azurerm_resource_group.quickstart]
}

module "generic_agents" {
  source = "../../modules/agents"

  name = "generic"
  resource_group_name = azurerm_resource_group.quickstart.name

  virtual_network_id = azurerm_virtual_network.vnet.id
  subnet_id = azurerm_subnet.snet.id

  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")
  instances = 1

  cluster_data = module.rke2.cluster_data

  tags = local.tags
}

#
# Dev/Example settings only
#
# Open up ssh on all the nodepools
resource "azurerm_network_security_rule" "ssh" {
  count = length(local.nodepool_nsgs)

  name = "${local.name}-ssh"
  access = "Allow"
  direction = "Inbound"
  network_security_group_name = local.nodepool_nsgs[count.index]
  priority = 201
  protocol = "Tcp"
  resource_group_name = azurerm_resource_group.quickstart.name

  source_address_prefix = "*"
  source_port_range = "*"
  destination_address_prefix = "*"
  destination_port_range = "22"
}

output "all" {
  value = module.rke2
}