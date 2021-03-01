output "network_security_group_name" {
  value = module.servers.network_security_group_name
}

output "token_vault_url" {
  value = module.statestore.vault_url
}

output "cluster_data" {
  value = {
    name = local.uname
    server_url = module.cp_lb.lb_url
    cluster_identity_id = azurerm_user_assigned_identity.cluster.id
    token = {
      vault_url = module.statestore.vault_url
      token_secret = module.statestore.token_secret_name
    }
  }
}