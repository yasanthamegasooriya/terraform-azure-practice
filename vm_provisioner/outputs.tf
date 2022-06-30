output "vnet_id" {
  value = azurerm_virtual_network.vnettf.id
}

output "subnet_id" {
  value = module.subnet_creation.subneta.id
}

# output "vm-private-ip" {
#   value = module.vm_creation.vm_details.private_ip_address
# }

# output "vm-public-ip" {
#   value = module.vm_creation.vm_details.public_ip_address
# }