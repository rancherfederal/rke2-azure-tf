variable "name" {
  type        = string
  description = "Name to give to the node pool"
}
variable "resource_group_name" {
  type        = string
  description = "Resource group where to put the node pool at"
}
variable "virtual_network_id" {
  type        = string
  description = "Virtual network id to deploy the node pool to"
}
variable "subnet_id" {
  type        = string
  description = "Subnet id to deploy the node pool to"
}
variable "admin_username" {
  type        = string
  description = "Admin username to use for the node pool"
}
variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key to use for the node pool"
}
variable "assign_public_ips" {
  type        = boolean
  description = "Whether to assign public ips to nodes"
}

variable "load_balancer_backend_address_pool_ids" {
  default     = []
  description = "List of backend address pool ids to use for the load balancer"
  type        = list(string)
}

variable "load_balancer_inbound_nat_rules_ids" {
  default     = []
  description = "List of inbound nat rules ids to use for the load balancer"
  type        = list(string)
}

variable "eviction_policy" {
  type        = string
  description = "The eviction policy to use for the node pool"
  default     = "Delete"
}

variable "priority" {
  type        = string
  description = "The priority to use for the node pool Allowed values (Regular, Spot)"
  default     = "Regular" #"Spot"
}

variable "health_probe_id" {
  type        = string
  description = "The health probe id to use for the node pool"
  default     = null
}

variable "instances" {
  type        = number
  description = "The number of nodes to create in the node pool"
  default     = 1
}

variable "upgrade_mode" {
  type        = string
  description = "The upgrade mode to use for the node pool"
  default     = "Automatic"
}

variable "nsg_id" {
  type        = string
  description = "The network security group id to use for the node pool"
}

variable "vm_size" {
  type        = string
  description = "The vm size to use for the node pool"
}

variable "identity_ids" {
  type        = list(string)
  description = "List of identities to assign to the node pool"
}

variable "additional_data_disks" {
  type = list(object({
    lun                  = number
    disk_size_gb         = number
    caching              = string
    storage_account_type = string
  }))
  description = "List of additional data disks to attach to the node pool"
}

variable "custom_data" {
  type        = string
  description = "Init script to run on each node"
}

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
  type        = map(string)
  description = "Tags to apply to the node pool"
  default     = {}
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "The storage account type to use for the node pool"
}

variable "os_disk_size_gb" {
  type        = number
  description = "The size of the OS disk in GB"
}

variable "os_disk_encryption_set_id" {
  type        = string
  description = "The encryption set id to use for the node pool"
}

variable "enable_automatic_instance_repair" {
  default     = false
  type        = bool
  description = "Whether to enable automatic instance repair"
}

variable "automatic_instance_repair_grace_period" {
  default     = null
  type        = string
  description = "The grace period to use for automatic instance repair"
}

variable "overprovision" {
  default     = false
  type        = bool
  description = "Whether to overprovision the node pool"
}
variable "zones" {
  type        = list(string)
  description = "List of availability zones to deploy the node pool to"
}
variable "zone_balance" {
  type        = bool
  description = "Whether to balance the node pool across availability zones"
}
variable "single_placement_group" {
  type        = bool
  description = "Whether to use a single placement group for the node pool"
}
variable "dns_servers" {
  type        = list(string)
  description = "List of DNS servers to use for the node pool"
}
variable "enable_accelerated_networking" {
  type        = bool
  description = "Whether to enable accelerated networking for the node pool"
}
