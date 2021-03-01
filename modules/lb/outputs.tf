output "lb_url" {
  value = azurerm_public_ip.pip.ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.bepool.id
}

//output "controlplane_nat_pool_id" {
//  value = azurerm_lb_nat_pool.controlplane.id
//}
//
//output "supervisor_nat_pool_id" {
//  value = azurerm_lb_nat_pool.supervisor.id
//}

output "controlplane_probe_id" {
  value = azurerm_lb_probe.this.id
}