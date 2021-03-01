variable "name" {}
variable "resource_group_name" {}
variable "subnet_id" {}
variable "tags" {
  default = {}
  type = map(string)
}