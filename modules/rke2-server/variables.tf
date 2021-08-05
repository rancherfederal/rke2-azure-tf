variable "cluster_name" {
  type        = string
  description = "Name of the server cluster"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to put the server cluster on"
}
variable "virtual_network_id" {
  type        = string
  description = "Id of the virtual network to put the server cluster on"
}
variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network to put the server cluster on"
}
variable "subnet_id" {
  type        = string
  description = "Id of the subnet to put the server cluster on"
}
variable "subnet_name" {
  type        = string
  description = "Name of the subnet to put the server cluster on"
}

variable "k8s_nsg_name" {
  type        = string
  description = "Name of the NSG to add to the server cluster"
}

variable "admin_username" {
  type        = string
  description = "Name of the admin user of the server cluster"
  default     = "rke2"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key of the admin user of the server cluster"
  default     = ""
}

variable "assign_public_ips" {
  type        = string
  description = "If true assign public IPs to nodes in the cluster"
  default     = false
}

variable "servers" {
  description = "Number of servers to create"
  type        = number
  default     = 1
}

variable "spot" {
  description = "Toggle spot requests for server pool"
  type        = bool
  default     = false
}

variable "controlplane_loadbalancer_type" {
  description = "Type of load balancer to use for the control plane"
  type        = string
  default     = "private"
}

variable "controlplane_loadbalancer_private_ip_address" {
  description = "IP address of the private load balancer for the control plane"
  type        = string
  default     = null
}

variable "controlplane_loadbalancer_private_ip_address_allocation" {
  description = "IP address allocation of the private load balancer for the control plane"
  type        = string
  default     = null
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
  default     = "Standard_DS4_v2"
  description = "Server pool vm size"
}

variable "rke2_version" {
  default = "v1.19.8+rke2r1"
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

variable "tags" {
  description = "(Optional) Tags to add to the server pool"
  type        = map(string)
  default     = {}
}

variable "zones" {
  description = "(Optional) List of availability zones servers should be created in."
  type        = list(number)
  default     = []
}
variable "zone_balance" {
  description = "(Optional) Toggle server balance within availability zones specified."
  default     = null
}

variable "single_placement_group" {
  description = "TODO: (Optional) Toggle single placement group."
  default     = null
}

variable "upgrade_mode" {
  description = "(Optional) Specify how upgrades should happen. Possible values are Automatic, Manual and Rolling. Defaults to Automatic."
  default     = "Automatic"
}

variable "priority" {
  description = "(Optional) Specify the priority of the VMSS.  Possible values are Regular and Spot. Defaults to Regular"
  default     = "Regular"
}

variable "eviction_policy" {
  description = "(Optional) Specify how server instances should be evicted. Possible values are Delete and Deallocate."
  default     = "Delete"
}

variable "dns_servers" {
  description = "(Optional) Specify any additional dns servers applied to server scale set."
  type        = list(string)
  default     = []
}

variable "enable_accelerated_networking" {
  description = "(Optional) Toggle accelerated networking for server scale set."
  type        = bool
  default     = false
}

variable "enable_automatic_instance_repair" {
  description = "(Optional) Toggle automatic instance repair."
  type        = bool
  default     = true
}

variable "automatic_instance_repair_grace_period" {
  description = "TODO: (Optional) Toggle accelerated networking for server scale set."
  type        = string
  default     = "PT50M"
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
  description = "TODO: Docs"
  type = list(object({
    lun                  = number
    disk_size_gb         = number
    caching              = string
    storage_account_type = string
  }))
  default = []
}

variable "cloud" {
  description = "(Optional) Cloud provider to use. Possible values are AzureUSGovernmentCloud, AzurePublicCloud"
  type        = string
  default     = "AzureUSGovernmentCloud"
  validation {
    condition     = contains(["AzureUSGovernmentCloud", "AzurePublicCloud"], var.cloud)
    error_message = "Allowed values for cloud are \"AzureUSGovernmentCloud\" or \"AzurePublicCloud\"."
  }
}

variable "public_ip" {
  description = "(Optional) if true, assign public IPs to nodes in the cluster"
  type        = bool
  default     = false
}

variable "open_ssh_public" {
  description = "(Optional) if true, allow ssh access to nodes in the cluster"
  type        = bool
  default     = false
}
