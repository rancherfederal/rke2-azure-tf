provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rke2" {
  name     = var.cluster_name
  location = var.location
}

resource "azurerm_virtual_network" "rke2" {
  name          = "${var.cluster_name}-vnet"
  address_space = ["10.0.0.0/16"]

  resource_group_name = azurerm_resource_group.rke2.name
  location            = azurerm_resource_group.rke2.location
}

resource "azurerm_subnet" "rke2" {
  name = "${var.cluster_name}-snet"

  resource_group_name  = azurerm_resource_group.rke2.name
  virtual_network_name = azurerm_virtual_network.rke2.name

  address_prefixes = ["10.0.1.0/24"]
}

module "rke2" {
  source                 = "../.."
  cluster_name           = var.cluster_name
  subnet_id              = azurerm_subnet.rke2.id
  server_public_ip       = var.server_public_ip
  server_open_ssh_public = var.server_open_ssh_public
  vm_size                = var.vm_size
  server_instance_count  = var.server_instance_count
  agent_instance_count   = var.agent_instance_count
  cloud                  = var.cloud
}
