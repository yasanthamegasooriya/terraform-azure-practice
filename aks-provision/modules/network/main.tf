resource "azurerm_virtual_network" "aks-rg" {
    name = "${var.prefix}-vnet"
    location = var.location
    resource_group_name = var.rg_name
    address_space = [var.vnet_cidr_block]
}
resource "azurerm_subnet" "aks-subent" {
    name = "${var.prefix}-subnet"
    resource_group_name = var.rg_name
    virtual_network_name = azurerm_virtual_network.aks-rg.name
    address_prefixes = [var.subnet_cidr_block]
  
}

