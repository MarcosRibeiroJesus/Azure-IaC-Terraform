provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Service Principal
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "primary" {}

# Resource Group
resource "azurerm_resource_group" "xpe" {
  name     = "myxpeResourceGroup"
  location = "East US"
}

# Custom Role Definition
resource "azurerm_role_definition" "custom" {
  name        = "VirtualMachineAndStorageContributor"
  scope       = data.azurerm_subscription.primary.id
  description = "This is a custom role created via Terraform"

  permissions {
     actions = [
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/*/write",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write"
    ]
  }
}

# Azure Key Vault
resource "azurerm_key_vault" "xpe" {
  name                        = "myxpekeyvault"
  resource_group_name         = azurerm_resource_group.xpe.name
  location                    = azurerm_resource_group.xpe.location
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  enabled_for_template_deployment = true
  tenant_id = data.azurerm_client_config.current.tenant_id
    
  sku_name = "standard"


  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Set"
    ]

    secret_permissions = [
        "Get", "List", "Set"
        ]

    storage_permissions = [
      "Get",
    ]
  }
}

# SSH Key Secret
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  key_vault_id = azurerm_key_vault.xpe.id
  value        = file(".ssh/id_rsa.pub")  # Update with the path to your SSH public key
}


# Virtual Network
resource "azurerm_virtual_network" "xpe" {
  name                = "myxpeVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.xpe.location
  resource_group_name = azurerm_resource_group.xpe.name
}

# Subnet
resource "azurerm_subnet" "xpe" {
  name                 = "myxpeSubnet"
  resource_group_name  = azurerm_resource_group.xpe.name
  virtual_network_name = azurerm_virtual_network.xpe.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "xpe" {
  name                = "myxpeNSG"
  resource_group_name = azurerm_resource_group.xpe.name
  location            = azurerm_resource_group.xpe.location
}

# Network Security Rule
resource "azurerm_network_security_rule" "xpe" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.xpe.name
  network_security_group_name = azurerm_network_security_group.xpe.name
}

# Public IP Address
resource "azurerm_public_ip" "xpe" {
  name                = "myxpePublicIP"
  location            = azurerm_resource_group.xpe.location
  resource_group_name = azurerm_resource_group.xpe.name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "xpe" {
  name                = "myxpeNIC"
  location            = azurerm_resource_group.xpe.location
  resource_group_name = azurerm_resource_group.xpe.name

  ip_configuration {
    name                          = "myxpeNICConfg"
    subnet_id                     = azurerm_subnet.xpe.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.xpe.id
  }
}

# Assign Virtual Machine Contributor role to service principal
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = azurerm_linux_virtual_machine.xpe.id
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Virtual Machine Contributor"
}


# Virtual Machine
resource "azurerm_linux_virtual_machine" "xpe" {
  name                = "myxpeVM"
  resource_group_name = azurerm_resource_group.xpe.name
  location            = azurerm_resource_group.xpe.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.xpe.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_key_vault_secret.ssh_public_key.value
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Storage Account
resource "azurerm_storage_account" "xpe" {
  name                     = "myxpestorageaccount"
  resource_group_name      = azurerm_resource_group.xpe.name
  location                 = azurerm_resource_group.xpe.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Assign Custom Role to Service Principal for Storage
resource "azurerm_role_assignment" "storage_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = azurerm_role_definition.custom.name
  scope                = azurerm_storage_account.xpe.id
}

# Container in Storage Account
resource "azurerm_storage_container" "xpe" {
  name                  = "myxpecontainer"
  storage_account_name  = azurerm_storage_account.xpe.name
  container_access_type = "private"
}
