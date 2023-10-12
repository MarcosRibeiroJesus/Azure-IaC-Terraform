# Azure Storage Backend for Terraform state
terraform {
  backend "azurerm" {
    resource_group_name   = azurerm_resource_group.xpe.name
    storage_account_name   = azurerm_storage_account.tfstate.name
    container_name         = "tfstatecontainer"
    key                    = "terraform.tfstate"
  }
}