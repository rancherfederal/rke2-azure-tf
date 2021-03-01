variable "name" {}

variable "resource_group_name" {}
variable "virtual_network_id" {}
variable "subnet_id" {}

variable "admin_username" {
  default = "rke2"
}

variable "admin_ssh_public_key" {
  default = ""
}

variable "assign_public_ips" {
  default = true
}

variable "instances" {
  description = "Number of agents to create"
  type = number
  default = 1
}

variable "spot" {
  description = "Toggle spot requests for server pool"
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
    offer = string
    sku = string
    version = string
  })

  default = {
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
  }
}

variable "vm_size" {
  type        = string
  default     = "Standard_F2"
  description = "Server pool vm size"
}

variable "rke2_version" {
  default = "v1.19.8+rke2r1"
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "cluster_data" {
  description = "Required data relevant to joining an existing rke2 cluster, sourced from main rke2 module, do NOT modify"

  type = object({
    name       = string
    server_url = string
    cluster_identity_id = string
    token = object({
      vault_url = string
      token_secret = string
    })
  })
}