/* data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
} */

resource "azurerm_public_ip" "pip" {
  count = var.type == "public" ? 1 : 0

  name              = "${var.name}-pip"
  allocation_method = "Static"
  sku               = "Standard"

  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge({}, var.tags)
}

resource "azurerm_lb" "this" {
  name = "${var.name}-cp"

  resource_group_name = var.resource_group_name
  location            = var.location

  sku = var.lb_sku

  frontend_ip_configuration {
    name                          = "${var.name}-lb-fe"
    public_ip_address_id          = var.type == "public" ? azurerm_public_ip.pip[0].id : null
    subnet_id                     = var.subnet_id[0]
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = var.private_ip_address_allocation
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
  resource_group_name = var.resource_group_name
  # Deprecated in future azurerm releases, ignore linting
  //  resource_group_name = ""
}

#
# Load Balancer health probe
#
resource "azurerm_lb_probe" "this" {
  name                = "${var.name}-lb-cp-probe"
  loadbalancer_id     = azurerm_lb.this.id
  resource_group_name = var.resource_group_name

  protocol            = "Tcp"
  interval_in_seconds = 10
  number_of_probes    = 3

  port = 6443
}

resource "azurerm_lb_rule" "controlplane" {
  name                = "${var.name}-cp"
  loadbalancer_id     = azurerm_lb.this.id
  resource_group_name = var.resource_group_name

  protocol      = "Tcp"
  frontend_port = 6443
  backend_port  = 6443

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
  probe_id                       = azurerm_lb_probe.this.id
}

resource "azurerm_lb_rule" "supervisor" {
  name                = "${var.name}-supervisor"
  loadbalancer_id     = azurerm_lb.this.id
  resource_group_name = var.resource_group_name

  protocol      = "Tcp"
  backend_port  = 9345
  frontend_port = 9345

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
  probe_id                       = azurerm_lb_probe.this.id
}

#
# Load Balancer NAT Pools
#
resource "azurerm_lb_nat_pool" "controlplane" {
  name = "${var.name}-lb-nat-pool-cp"
  loadbalancer_id = azurerm_lb.this.id
  resource_group_name = var.resource_group_name

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  protocol = "Tcp"
  frontend_port_start = 6443
  frontend_port_end = sum([6443, 1])
  backend_port = 6443
}

resource "azurerm_lb_nat_pool" "supervisor" {
  name = "${var.name}-lb-nat-pool-supervisor"
  loadbalancer_id = azurerm_lb.this.id
  resource_group_name = var.resource_group_name

  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration.0.name
  protocol = "Tcp"
  backend_port = 9345
  frontend_port_start = 9345
  frontend_port_end = sum([9345, 1])
}

resource "azurerm_nat_gateway" "nat" {
  name = "${var.name}-nat-gw"

  resource_group_name  = var.resource_group_name
  location             =  var.location
  public_ip_prefix_ids = [azurerm_public_ip_prefix.nat.id]

  #tags = var.tags
}

resource "azurerm_subnet_nat_gateway_association" "assc" {
  subnet_id      = var.vnet_subnets[0]
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_public_ip_prefix" "nat" {
  name = "${var.name}-nat-pips"

  resource_group_name = var.resource_group_name
  location            = var.location
# TODO make var
  prefix_length = 30

  #tags = local.tags
}