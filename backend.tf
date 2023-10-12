# Azure Storage Backend for Terraform state
terraform {
  backend "azurerm" {
    resource_group_name   = "myxpeResourceGroup"
    storage_account_name   = "tfstatestorageaccount"
    container_name         = "tfstatecontainer"
    key                    = "terraform.tfstate"
  }
}