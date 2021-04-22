variable "name" {
    type = string
}
variable "location" {
    type = string
}
variable "resource_group_name" {
    type = string
}
variable "token" {
    type = string
}
variable "reader_object_id" {
    type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_ids" {
    type = list(string)
    
}