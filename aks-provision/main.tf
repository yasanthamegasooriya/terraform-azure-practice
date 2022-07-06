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

resource "azurerm_virtual_network" "aks-rg" {
    name = "${var.prefix}-vnet"
    location = azurerm_resource_group.aks-rg.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    address_space = [var.vnet_cidr_block]
}
resource "azurerm_subnet" "aks-subent" {
    name = "${var.prefix}-subnet"
    resource_group_name = azurerm_resource_group.aks-rg.name
    virtual_network_name = azurerm_virtual_network.aks-rg.name
    address_prefixes = [var.subnet_cidr_block]
  
}

# resource "azuread_group" "aks-administrator" {
# #  name = "${azurerm_resource_group.aks-rg.name}-cluster-administrator"
#   display_name = "${azurerm_resource_group.aks-rg.name}-cluster-administrator"
#   description = "Azure AKS Kubernetes administrators for the ${azurerm_resource_group.aks-rg.name}-cluster."
# }

resource "azurerm_log_analytics_workspace" "insights" {
  name                = "${var.prefix}-logs"
  location            = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name = "${var.prefix}-cluster"
  location = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  dns_prefix = "${azurerm_resource_group.aks-rg.name}-cluster"
  kubernetes_version = data.azurerm_kubernetes_service_versions.current.latest_version
  
  default_node_pool{

    name = "defaultpool"
    vm_size = "Standard_DS2_v2"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
#    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
#    role_based_access_control_enabled = true
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = "dev"
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
    }
    tags = {
      "nodepool-type"    = "system"
      "environment"      = "dev"
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
   } 
   
  }
    identity {
    type = "SystemAssigned"
   }
  #  addon_profile {
  #   azure_policy {enabled =  true}
  #   oms_agent {
  #     enabled =  true
  #     log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
  #   }
  #   }
  
  #   role_based_access_control {
  #   enabled = true
  #   azure_active_directory {
  #     managed = true
  #     admin_group_object_ids = [azuread_group.aks_administrators.id]
  #   }
  # }
  
    linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }
  
    network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
}