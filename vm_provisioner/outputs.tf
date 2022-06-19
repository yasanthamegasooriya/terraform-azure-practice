output "vnet_id" {
  value = azurerm_virtual_network.vnettf.id
}

output "subnet_id" {
  value = azurerm_subnet.vnettfsubenta.id
}

output "vm-private-ip" {
  value = azurerm_linux_virtual_machine.tfvm.private_ip_address
}

output "vm-public-ip" {
  value = azurerm_linux_virtual_machine.tfvm.public_ip_address
}