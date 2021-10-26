output "rke2_cluster" {
  description = "RKE2 cluster data created"
  value       = module.rke2_cluster.cluster_data
}

output "kv_name" {
  description = "Name of the key vault created"
  value       = module.rke2_cluster.token_vault_name
}

output "rg_name" {
  description = "Name of the resource group used"
  value       = local.resource_group_name
}
