data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_template_deployment = true

  tags = merge({}, var.tags)
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.this.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  key_permissions = []

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "service_reader" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.reader_object_id

  key_permissions         = []
  secret_permissions      = ["Get", "Set"]
  certificate_permissions = []
  storage_permissions     = []

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_key_vault_secret" "token" {
  name         = "${var.name}-token"
  key_vault_id = azurerm_key_vault.this.id
  value        = var.token
  tags         = merge({}, var.tags)

  depends_on = [azurerm_key_vault_access_policy.policy]
}

variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "token" {}
variable "reader_object_id" {}
variable "tags" {
  type    = map(string)
  default = {}
}

output "vault_url" {
  value = azurerm_key_vault.this.vault_uri
}

output "token_secret_name" {
  value = azurerm_key_vault_secret.token.name
}

output "vault_name" {
  value = azurerm_key_vault.this.name
}

output "vault_id" {
  value = azurerm_key_vault.this.id
}
