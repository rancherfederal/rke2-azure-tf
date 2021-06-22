output "vault_url" {
  value = azurerm_key_vault.this.vault_uri
}

output "token_secret_name" {
  value = azurerm_key_vault_secret.token.name
}

output "vault_name" {
  value = azurerm_key_vault.this.name
}