variable "cluster_name" {
  description = "Prefix used for all resources"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where to deploy the cluster resources"
  type        = string

}

variable "cloud" {
  description = "Which Azure cloud to use"
  type        = string
  default     = "AzureUSGovernmentCloud"
  validation {
    condition     = contains(["AzureUSGovernmentCloud", "AzurePublicCloud"], var.cloud)
    error_message = "Allowed values for cloud are \"AzureUSGovernmentCloud\" or \"AzurePublicCloud\"."
  }
}

variable "server_public_ip" {
  description = "Assign a public IP to the control plane load balancer"
  type        = bool
  default     = false
}

variable "server_open_ssh_public" {
  description = "Allow SSH to the server nodes through the control plane load balancer"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "Default VM size to use for the cluster"
  type        = string
  default     = "Standard_D8_v3"
}

variable "server_vm_size" {
  type        = string
  description = "VM size to use for the server nodes"
  default     = ""
}

variable "agent_vm_size" {
  type        = string
  description = "VM size to use for the agent nodes"
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

variable "resource_group_name" {
  description = "(Optional) the name of an existing resource group to be used if not specified the subnet resource group will be used"
  type        = string
  default     = ""
}
