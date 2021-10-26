variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_id" {
  description = "Id of the virtual network to deploy the cluster on"
  type        = string
}

variable "subnet_id" {
  description = "Id of the subnet to deploy the cluster on"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network to deploy the cluster on"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet to deploy the cluster on"
  type        = string
}

variable "cloud" {
  description = "Cloud provider to use"
  type        = string
  default     = "AzureUSGovernmentCloud"
  validation {
    condition     = contains(["AzureUSGovernmentCloud", "AzurePublicCloud"], var.cloud)
    error_message = "Allowed values for cloud are \"AzureUSGovernmentCloud\" or \"AzurePublicCloud\"."
  }
}

variable "vm_size" {
  description = "Size of the VM to deploy trhe cluster at"
  type        = string
  default     = "Standard_DS4_v3"
}

variable "server_vm_size" {
  type        = string
  description = "VM size to use for the server nodes if you do not specify vm_size will be used"
  default     = ""
}

variable "agent_vm_size" {
  type        = string
  description = "VM size to use for the agent nodes if you do not specify vm_size will be used"
  default     = ""
}

variable "server_instance_count" {
  description = "Number of server nodes to deploy"
  type        = number
  default     = 1
}

variable "agent_instance_count" {
  description = "Number of agent nodes to deploy"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = object({})
  default     = {}
}

variable "server_public_ip" {
  description = "If true assign a public ip to the server nodes"
  type        = bool
  default     = false
}

variable "server_open_ssh_public" {
  description = "If true open the ssh port for the server nodes"
  type        = bool
  default     = false
}
