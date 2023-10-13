variable "subscription_id" {}

variable "tenant_id" {}

variable "client_id" {}

variable "azurerm_resource_group_name" {
  type    = string
  default = "myxpeResourceGroup" 
}

variable "azurerm_resource_group_location" {
  type    = string
  default = "East US" 
}