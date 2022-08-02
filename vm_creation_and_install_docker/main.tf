terraform {
  required_version = ">= 0.12"
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
resource "azurerm_public_ip" "public_ip_address" {
  count               = var.number_of_vms
  name                = "${var.env_prefix}-public_ip_address-${count.index}"
  resource_group_name = azurerm_resource_group.rgtf.name
  location            = azurerm_resource_group.rgtf.location
  allocation_method   = "Static"

  tags = {
    environment = "${var.env_prefix}"
  }
}
# resource "tls_private_key" "ssh_pem" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

data "azurerm_ssh_public_key" "public_key" {
  name                = "vm1-key"
  resource_group_name = "existing_rg"
}
resource "azurerm_network_interface" "tfinterface" {
  count               = var.number_of_vms
  name                = "${var.env_prefix}-interface-${count.index}"
  location            = azurerm_resource_group.rgtf.location
  resource_group_name = azurerm_resource_group.rgtf.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnettfsubenta.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_address[count.index].id

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
  count               = var.number_of_vms
  name                = "${var.env_prefix}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.rgtf.name
  location            = azurerm_resource_group.rgtf.location
  size                = "Standard_DS1_v2"
  admin_username      = "yasantha"
  network_interface_ids = [
    azurerm_network_interface.tfinterface[count.index].id,
  ]
  #admin_password                  = "Yasantha@1995"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "yasantha"
    public_key = data.azurerm_ssh_public_key.public_key.public_key
  }
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
  count= var.number_of_vms
  network_interface_id      = azurerm_network_interface.tfinterface[count.index].id
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

