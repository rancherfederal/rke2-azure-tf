variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}
variable "virtual_network_id" {
  type = string
}
variable "subnet_id" {
  type = list(string)
  default = null
}

variable "admin_username" {
  type = string
  default = "rke2"
}

variable "admin_ssh_public_key" {
  default = ""
  type = string
}

variable "assign_public_ips" {
  default = false
  type = bool
}

variable "instances" {
  description = "Number of agents to create"
  type        = number
  default     = 1
}

variable "spot" {
  description = "Toggle spot requests for server pool"
  type        = bool
  default     = false
}

variable "pre_userdata" {
  description = "(Optional) Additional userdata to be ran immediately before cluster bootstrapping."
  type        = string
  default     = ""
}

variable "post_userdata" {
  description = "(Optional) Additional userdata to be ran post cluster bootstrapping."
  type        = string
  default     = ""
}

variable "rke2_config" {
  description = "(Optional) Additional RKE2 configuration in config file format: https://docs.rke2.io/install/install_options/install_options/#configuration-file"
  type        = string
  default     = ""
}

variable "enable_ccm" {
  description = "(Optional) Enable in tree Azure Cloud Controller Manager in RKE2."
  type        = bool
  default     = false
}

#
# Server pool variables
#
variable "source_image_reference" {
  description = "Source image query parameters"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    offer     = "UbuntuServer"
    publisher = "Canonical"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "vm_size" {
  type        = string
  default     = "Standard_F2"
  description = "Server pool vm size"
}

variable "rke2_version" {
  default = "v1.19.8+rke2r1"
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cluster_data" {
  description = "Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module, do NOT modify"

  type = object({
    name                = string
    server_url          = string
    cluster_identity_id = string
    token = object({
      vault_url    = string
      token_secret = string
    })
  })
}

variable "overprovision" {
  description = "(Optional) Toggle agent scaleset overprovisioning."
  default     = true
  type        = bool
}

variable "zones" {
  description = "(Optional) List of availability zones agents should be created in."
  type        = list(number)
  default     = []
}
variable "zone_balance" {
  description = "(Optional) Toggle server balance within availability zones specified."
  default     = null
  type        = bool
}

variable "single_placement_group" {
  description = "TODO: (Optional) Toggle single placement group."
  default     = null
  type        = bool
}

variable "upgrade_mode" {
  description = "(Optional) Specify how upgrades should happen. Possible values are Automatic, Manual and Rolling. Defaults to Automatic."
  default     = "Automatic"
  type        = string
}

variable "priority" {
  description = "(Optional) Specify the priority of the VMSS.  Possible values are Regular and Spot. Defaults to Regular"
  default     = "Regular"
  type        = string
}

variable "eviction_policy" {
  description = "(Optional) Specify how server instances should be evicted. Possible values are Delete and Deallocate."
  default     = "Delete"
  type        = string
}

variable "dns_servers" {
  description = "(Optional) Specify any additional dns agents applied to server scale set."
  type        = list(string)
  default     = []
}

variable "enable_accelerated_networking" {
  description = "(Optional) Toggle accelerated networking for server scale set."
  type        = bool
  default     = false
}

variable "os_disk_storage_account_type" {
  description = "(Optional) Storage Account used for OS Disk.  Possible values include Standard_LRS or Premium_LRS."
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_size_gb" {
  description = "(Optional) Storage disk size for OS in GB. Defaults to 30Gb"
  type        = number
  default     = 30
}

variable "os_disk_encryption_set_id" {
  description = "TODO: Docs"
  type        = string
  default     = null
}

variable "additional_data_disks" {
  type = list(object({
    lun                  = number
    disk_size_gb         = number
    caching              = string
    storage_account_type = string
  }))
  default = []
}

variable "location" {
  type = string
}