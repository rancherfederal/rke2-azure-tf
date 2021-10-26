variable "agent" {
  description = "Toggle server or agent init, defaults to agent"
  type        = bool
  default     = true
}

variable "server_url" {
  description = "rke2 server url"
  type        = string
}

variable "vault_url" {
  description = "Vault url where token secret is located"
  type        = string
}

variable "token_secret" {
  description = "Secret name of token in key vault"
  type        = string
}

variable "config" {
  description = "RKE2 config file yaml contents"
  type        = string
  default     = ""
}

variable "ccm" {
  description = "Toggle cloud controller manager"
  type        = bool
  default     = false
}

variable "cloud" {
  type    = string
  default = "AzureUSGovernmentCloud"
  validation {
    condition     = contains(["AzureUSGovernmentCloud", "AzurePublicCloud"], var.cloud)
    error_message = "Allowed values for cloud are \"AzureUSGovernmentCloud\" or \"AzurePublicCloud\"."
  }
}

variable "node_labels" {
  description = "Node labels to add to the cluster"
  type        = string
  default     = "[]"
}

variable "node_taints" {
  description = "Node taints to add to the cluster"
  type        = string
  default     = "[]"
}

#
# Custom Userdata
#
variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 node attempts to join cluster"
  default     = ""
}


