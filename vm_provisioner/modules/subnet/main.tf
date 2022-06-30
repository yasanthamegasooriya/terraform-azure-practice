resource "azurerm_subnet" "vnettfsubenta" {
  name                 = var.subnet-name
  virtual_network_name = var.vnet-name
  address_prefixes     = [var.subent_cidr_block]
  resource_group_name  = var.rg-name
}