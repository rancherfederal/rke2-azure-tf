data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_template_deployment = true
  network_acls {
    #virtual_network_subnet_ids = var.subnet_ids
    bypass = "AzureServices"
    default_action = "Allow"
  }
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

  key_permissions         = ["get", "list", "create"]
  secret_permissions      = ["get", "list", "set"]
  certificate_permissions = ["get", "list"]
  storage_permissions     = ["list", "set", "get"]

  lifecycle {
    create_before_destroy = true
  }
}

//resource "azurerm_key_vault_access_policy" "working" {
//  key_vault_id = azurerm_key_vault.this.id
//  tenant_id = ""
//  object_id = ""
//
//  key_permissions = []
//  secret_permissions = ["Get", "List"]
//  certificate_permissions = []
//  storage_permissions = []
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}

resource "azurerm_key_vault_secret" "token" {
  name         = "${var.name}-token"
  key_vault_id = azurerm_key_vault.this.id
  value        = var.token
  tags         = merge({}, var.tags)

  depends_on = [azurerm_key_vault_access_policy.policy]
}