output "scale_set_id" {
  value = azurerm_linux_virtual_machine_scale_set.this.id
}

output "network_security_group_id" {
  value = azurerm_network_security_group.this.id
}

output "network_security_group_name" {
  value = azurerm_network_security_group.this.name
}
