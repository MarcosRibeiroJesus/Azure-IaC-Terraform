variable "SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = string
}

variable "TENANT_ID" {
  description = "Azure Tenant ID"
  type        = string
}

variable "CLIENT_ID" {
  description = "Azure Client ID"
  type        = string
}
variable "azurerm_resource_group_name" {
  type    = string
  default = "myxpeResourceGroup" 
}

variable "azurerm_resource_group_location" {
  type    = string
  default = "East US" 
}