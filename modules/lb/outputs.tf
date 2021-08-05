output "lb_url" {
  value = var.type == "public" ? azurerm_public_ip.pip[0].ip_address : azurerm_lb.this.private_ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.bepool.id
}

output "azurerm_lb_nat_pool_ssh_id" {
  value = azurerm_lb_nat_pool.ssh.id
}

output "controlplane_probe_id" {
  value = azurerm_lb_probe.this.id
}
