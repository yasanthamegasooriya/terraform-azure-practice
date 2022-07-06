terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "aks-rg" {
  name = "${var.prefix}-rg"
  location = "eastus"
}

data "azurerm_kubernetes_service_versions" "current" {
  location = azurerm_resource_group.aks-rg.location
  include_preview = false
}

module "network_and_subnet" {
  source = "./modules/network"
  prefix = var.prefix
  location = azurerm_resource_group.aks-rg.location
  rg_name = azurerm_resource_group.aks-rg.name
  vnet_cidr_block = var.vnet_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
}

resource "azurerm_log_analytics_workspace" "insights" {
  name                = "${var.prefix}-logs"
  location            = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  retention_in_days   = 30
}
module "aks" {
  source = "./modules/aks"
  prefix = var.prefix
  location = azurerm_resource_group.aks-rg.location
  rg_name = azurerm_resource_group.aks-rg.name
  latest_version = data.azurerm_kubernetes_service_versions.current.latest_version
  ssh_public_key = var.ssh_public_key

}

