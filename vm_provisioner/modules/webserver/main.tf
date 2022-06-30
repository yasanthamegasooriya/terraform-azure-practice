
resource "azurerm_public_ip" "public_ip_address" {
  name                = "${var.env_prefix}-public_ip_address"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"

  tags = {
    environment = "${var.env_prefix}"
  }
}

resource "azurerm_network_interface" "tfinterface" {
  name                = "${var.env_prefix}-interface"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_address.id

  }
}


resource "azurerm_network_security_group" "vm-nsg" {
  name                = "${var.env_prefix}-nsg"
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_network_security_rule" "vm-nsg-rule-1" {
  name                        = "${var.env_prefix}-nsr-1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.vm-nsg.name
}


resource "azurerm_network_security_rule" "vm-nsg-rule-2" {
  name                        = "${var.env_prefix}-nsr-2"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.vm-nsg.name
}
/*
data "template_file" "linux-vm-docker-setup" {
  template = file("docker_install.sh")
}
*/



resource "azurerm_linux_virtual_machine" "tfvm" {
  name                = "${var.env_prefix}-vm"
  resource_group_name = var.rg_name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = "yasantha"
  network_interface_ids = [
    azurerm_network_interface.tfinterface.id,
  ]
  admin_password                  = "Yasantha@1995"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  # connection {
  # type = "ssh"
  # host = self.public_ip_address
  # user = "yasantha"
  # password = "Yasantha@1995"
  # }

  # provisioner "file" {
  #   source="docker_install.sh"
  #   destination = "/home/yasantha/docker_install.sh"
  # }
  # provisioner "remote-exec" {
  #   script = file("docker_install.sh")    
  # }
  //custom_data = base64encode(data.template_file.linux-vm-docker-setup.rendered)
  //custom_data = filebase64("./docker_install.tpl")
  //user_data = file("./docker_install.sh")
}

resource "azurerm_network_interface_security_group_association" "nsg-vm-as" {
  network_interface_id      = azurerm_network_interface.tfinterface.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id

}
/*
resource "azurerm_virtual_machine_extension" "vm-extension" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_linux_virtual_machine.tfvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"


  settings = <<SETTINGS
  {
  "fileUris": ["https://sag.blob.core.windows.net/sagcont/docker_install.sh"],
    "commandToExecute": "sh docker_install.sh"
  }
              SETTINGS

}
*/
