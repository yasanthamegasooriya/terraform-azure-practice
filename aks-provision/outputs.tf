output "client_certificate" {
  value     = module.aks.aks_details.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = module.aks.aks_details.kube_config_raw

  sensitive = true
}

