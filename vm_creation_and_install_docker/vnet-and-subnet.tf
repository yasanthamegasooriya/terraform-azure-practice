resource "azurerm_virtual_network" "vnettf" {
  name                = "${var.env_prefix}-vnet"
  location            = azurerm_resource_group.rgtf.location
  address_space       = [var.vnet_cidr_block]
  resource_group_name = azurerm_resource_group.rgtf.name
  tags = {
    "Name" = "${var.env_prefix}-vnet"
  }
}

resource "azurerm_subnet" "vnettfsubenta" {
  name                 = "${var.env_prefix}-subneta"
  virtual_network_name = azurerm_virtual_network.vnettf.name
  address_prefixes     = [var.subent_cidr_block]
  resource_group_name  = azurerm_resource_group.rgtf.name

}