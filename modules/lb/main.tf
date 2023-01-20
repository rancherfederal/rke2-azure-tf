data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "pip" {
  count = var.type == "public" ? 1 : 0

  name              = "${var.name}-pip"
  allocation_method = "Static"
  sku               = "Standard"
  zones             = [var.zone]

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location


  tags = merge({}, var.tags)
}

resource "azurerm_lb" "this" {
  name = "${var.name}-cp"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku = "Standard"

  frontend_ip_configuration {
    name                          = "${var.name}-lb-fe"
    public_ip_address_id          = var.type == "public" ? azurerm_public_ip.pip[0].id : null
    subnet_id                     = var.type == "public" ? null : var.subnet_id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = var.private_ip_address_allocation
    zones                         = [var.zone]
  }

  tags = merge({}, var.tags)
}

#
# Load Balancer backend address pool
#
//noinspection MissingProperty
resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "${var.name}-lbe-be-pool"
  loadbalancer_id = azurerm_lb.this.id
}

#
# Load Balancer health probe
#
resource "azurerm_lb_probe" "this" {
  name                = "${var.name}-lb-cp-probe"
  loadbalancer_id     = azurerm_lb.this.id

  protocol            = "Tcp"
  interval_in_seconds = 10
  number_of_probes    = 3

  port = 6443
}

resource "azurerm_lb_rule" "controlplane" {
  name                = "${var.name}-cp"
  loadbalancer_id     = azurerm_lb.this.id

  protocol      = "Tcp"
  frontend_port = 6443
  backend_port  = 6443

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.this.id
}

resource "azurerm_lb_rule" "supervisor" {
  name                = "${var.name}-supervisor"
  loadbalancer_id     = azurerm_lb.this.id

  protocol      = "Tcp"
  backend_port  = 9345
  frontend_port = 9345

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.this.id
}


resource "azurerm_lb_nat_pool" "ssh" {
  resource_group_name            = data.azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "SSHNatPool"
  protocol                       = "Tcp"
  frontend_port_start            = 5000
  frontend_port_end              = 5100
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.name}-lb-fe"
}

