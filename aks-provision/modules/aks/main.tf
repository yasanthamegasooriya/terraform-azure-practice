resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name = "${var.prefix}-cluster"
  location = var.location
  resource_group_name = var.rg_name
  dns_prefix = "${var.rg_name}-cluster"
  kubernetes_version = var.latest_version
  
  default_node_pool{

    name = "defaultpool"
    vm_size = "Standard_DS2_v2"
    orchestrator_version = var.latest_version
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