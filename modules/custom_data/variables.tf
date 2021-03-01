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
