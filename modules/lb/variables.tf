variable "name" {}

variable "resource_group_name" {}

variable "type" {
  description = "(Optional) Toggle between private or public load balancer"
  type        = string
  default     = "private"
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "private_ip_address" {
  type    = string
  default = null
}

variable "private_ip_address_allocation" {
  type    = string
  default = null
}

variable "lb_sku" {
  type    = string
  default = "Standard"
}

variable "tags" {
  default = {}
  type    = map(string)
}

variable "zone" {
  description = "(Optional) Defaults to No-Zone. Possible values Zone-Redundant, 1, 2, 3, No-Zone"
  type        = string
  default     = "No-Zone"
}