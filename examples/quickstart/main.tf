provider "azurerm" {
  features {}
}

locals {
  name = "rke2-quickstart"
  tags = {
    "Environment" = local.name,
    "Terraform"   = "true",
  }

  //  nodepool_nsgs = [module.rke2.network_security_group_name, module.generic_agents.network_security_group_name]
  nodepool_nsgs = [module.rke2.network_security_group_name]
}

resource "azurerm_resource_group" "quickstart" {
  name     = local.name
  location = "Central US"
}

resource "azurerm_virtual_network" "vnet" {
  name          = "${local.name}-vnet"
  address_space = ["10.0.0.0/16"]

  resource_group_name = azurerm_resource_group.quickstart.name
  location            = azurerm_resource_group.quickstart.location

  tags = local.tags
}

resource "azurerm_subnet" "snet" {
  name = "${local.name}-snet"

  resource_group_name  = azurerm_resource_group.quickstart.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_nat_gateway" "nat" {
  name = "${local.name}-nat-gw"

  resource_group_name  = azurerm_resource_group.quickstart.name
  location             = azurerm_resource_group.quickstart.location
  public_ip_prefix_ids = [azurerm_public_ip_prefix.nat.id]

  tags = local.tags
}

resource "azurerm_subnet_nat_gateway_association" "assc" {
  subnet_id      = azurerm_subnet.snet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_subnet" "bastion-snet" {
  name = "AzureBastionSubnet"

  resource_group_name  = azurerm_resource_group.quickstart.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.0.224/27"]
}

resource "azurerm_public_ip_prefix" "nat" {
  name = "${local.name}-nat-pips"

  resource_group_name = azurerm_resource_group.quickstart.name
  location            = azurerm_resource_group.quickstart.location

  prefix_length = 30

  tags = local.tags
}

resource "azurerm_public_ip" "bastion" {
  name = "${local.name}-bastion-pip"

  resource_group_name = azurerm_resource_group.quickstart.name
  location            = azurerm_resource_group.quickstart.location

  allocation_method = "Static"
  sku               = "Standard"

  tags = local.tags
}

resource "azurerm_bastion_host" "bastion" {
  name = "${local.name}-bastion"

  resource_group_name = azurerm_resource_group.quickstart.name
  location            = azurerm_resource_group.quickstart.location

  ip_configuration {
    name                 = "${local.name}-bastion-config"
    subnet_id            = azurerm_subnet.bastion-snet.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.tags
}

module "rke2" {
  source = "../.."

  cluster_name        = local.name
  resource_group_name = azurerm_resource_group.quickstart.name

  virtual_network_id = azurerm_virtual_network.vnet.id
  subnet_id          = azurerm_subnet.snet.id

  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  servers  = 1
  priority = "Spot"

  tags = local.tags

  # Needed to ensure zero to nothing works when azure RGs don't exist already
  depends_on = [azurerm_resource_group.quickstart]
}

module "generic_agents" {
  source       = "../../modules/agents"
  cluster_data = module.rke2.cluster_data

  name                = "generic"
  resource_group_name = azurerm_resource_group.quickstart.name

  virtual_network_id = azurerm_virtual_network.vnet.id
  subnet_id          = azurerm_subnet.snet.id

  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  instances = 1
  priority  = "Spot"

  tags = local.tags

  # Needed to ensure zero to nothing works when azure RGs don't exist already
  depends_on = [azurerm_resource_group.quickstart]
}

#
# Dev/Example settings only
#
# Open up ssh on all the nodepools
resource "azurerm_network_security_rule" "ssh" {
  count = length(local.nodepool_nsgs)

  name                        = "${local.name}-ssh"
  access                      = "Allow"
  direction                   = "Inbound"
  network_security_group_name = local.nodepool_nsgs[count.index]
  priority                    = 201
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.quickstart.name

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "22"
}

# Example method of fetching kubeconfig from state store, requires azure cli and bash locally
resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "az keyvault secret show --name kubeconfig --vault-name ${module.rke2.token_vault_name} | jq -r '.value' > rke2.yaml"
  }
}

# Output everything for demo purposes
output "all" {
  value = module.rke2
}

output "bastion_pip" {
  value = azurerm_public_ip.bastion.ip_address
}