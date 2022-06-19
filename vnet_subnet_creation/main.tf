provider "azurerm" {
  features {
  }
} 

variable "subnet_vnettfsubneta_name" {
  description="ip cidr block for "
}
variable "vnet_and_subnet_name_cidr" {
  description = "subnet name and cidr block on vnet and subnet"
  type = list(object({
    name=string,
    cidr_block=string

  }))

}
resource "azurerm_resource_group" "rgtf" {
  name = "rgtf"
  location = "West Europe"
}
resource "azurerm_virtual_network" "vnettf"{
  name = var.vnet_and_subnet_name_cidr[0].name
  location = azurerm_resource_group.rgtf.location
  address_space = [var.vnet_and_subnet_name_cidr[0].cidr_block]
  resource_group_name = azurerm_resource_group.rgtf.name
  tags = {
    "Name" = var.vnet_and_subnet_name_cidr[0].name
  }
}

resource "azurerm_subnet" "vnettfsubenta"{
    name = var.subnet_vnettfsubneta_name
    virtual_network_name=azurerm_virtual_network.vnettf.name
    address_prefixes = [var.vnet_and_subnet_name_cidr[1].cidr_block]
    resource_group_name = azurerm_resource_group.rgtf.name
}


data "azurerm_virtual_network" "existing_vnet" {
  resource_group_name = "existing_rg"
  name = "existing_vnet"
}


resource "azurerm_subnet" "existing_subnetb" {
  name = "existing_subnetb"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  address_prefixes = [ "10.0.1.0/24" ]
  resource_group_name = data.azurerm_virtual_network.existing_vnet.resource_group_name
}

output "vnet_id" {
  value=azurerm_virtual_network.vnettf.id
}

output "subnet_id" {
  value=azurerm_subnet.vnettfsubenta.id
}