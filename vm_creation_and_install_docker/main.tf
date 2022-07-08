terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
}

variable "vnet_cidr_block" {

}

variable "subent_cidr_block" {

}

variable "env_prefix" {

}
/*
locals {
  custom_data = <<CUSTOM_DATA
  sudo apt-get update -y
sudo apt-get install \
              ca-certificates \
              curl \
              gnupg \
              lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo docker run -p 8080:80 nginx
  CUSTOM_DATA
}
*/
resource "azurerm_resource_group" "rgtf" {
  name     = "rgtf"
  location = "West Europe"
}
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
resource "azurerm_public_ip" "public_ip_address" {
  name                = "${var.env_prefix}-public_ip_address"
  resource_group_name = azurerm_resource_group.rgtf.name
  location            = azurerm_resource_group.rgtf.location
  allocation_method   = "Static"

  tags = {
    environment = "${var.env_prefix}"
  }
}

resource "azurerm_network_interface" "tfinterface" {
  name                = "${var.env_prefix}-interface"
  location            = azurerm_resource_group.rgtf.location
  resource_group_name = azurerm_resource_group.rgtf.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnettfsubenta.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_address.id

  }
}


resource "azurerm_network_security_group" "vm-nsg" {
  name                = "${var.env_prefix}-nsg"
  location            = azurerm_resource_group.rgtf.location
  resource_group_name = azurerm_resource_group.rgtf.name
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
  resource_group_name         = azurerm_resource_group.rgtf.name
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
  resource_group_name         = azurerm_resource_group.rgtf.name
  network_security_group_name = azurerm_network_security_group.vm-nsg.name
}

resource "azurerm_network_security_rule" "vm-nsg-rule-3" {
  name                        = "${var.env_prefix}-nsr-3"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgtf.name
  network_security_group_name = azurerm_network_security_group.vm-nsg.name
}
/*
data "template_file" "linux-vm-docker-setup" {
  template = file("docker_install.sh")
}
*/


resource "azurerm_linux_virtual_machine" "tfvm" {
  name                = "${var.env_prefix}-vm"
  resource_group_name = azurerm_resource_group.rgtf.name
  location            = azurerm_resource_group.rgtf.location
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
    sku       = "18.04-LTS"
    version   = "latest"
  }
  //custom_data = base64encode(data.template_file.linux-vm-docker-setup.rendered)
  custom_data = filebase64("./docker_install.tpl")
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