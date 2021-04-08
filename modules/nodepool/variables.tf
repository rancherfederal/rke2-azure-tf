variable "name" {}
variable "resource_group_name" {}
variable "virtual_network_id" {}
variable "subnet_id" {
  type = list(string)
}
variable "admin_username" {}
variable "admin_ssh_public_key" {}
variable "assign_public_ips" {}

variable "load_balancer_backend_address_pool_ids" {
  default = []
  type    = list(string)
}

variable "load_balancer_inbound_nat_rules_ids" {
  default = []
  type    = list(string)
}

variable "eviction_policy" {
  default = "Delete"
}
variable "priority" {
  default = "Spot"
}

variable "health_probe_id" {
  default = null
}

variable "instances" {
  type    = number
  default = 1
}

variable "upgrade_mode" {
  type    = string
  default = "Automatic"
}

variable "nsg_id" {}

variable "vm_size" {}

variable "identity_ids" {
  type = list(string)
}

variable "additional_data_disks" {}

variable "custom_data" {}

variable "source_image_id" {
  description = "ID of an image to use for each VM in the scale set."
  default     = null
}

variable "source_image_reference" {
  description = "Source image query parameters"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "os_disk_storage_account_type" {}

variable "os_disk_size_gb" {}

variable "os_disk_encryption_set_id" {}

variable "enable_automatic_instance_repair" {
  default = false
  type    = bool
}

variable "automatic_instance_repair_grace_period" {
  default = null
  type    = string
}

variable "overprovision" {}
variable "zones" {}
variable "zone_balance" {}
variable "single_placement_group" {}
variable "dns_servers" {}
variable "enable_accelerated_networking" {}
variable "os_upgrade_policy" {
  type = bool
  default = true
}
variable "location" {}