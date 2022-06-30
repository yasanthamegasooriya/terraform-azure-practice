terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {
  }
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
  name     = var.rg_name
  location = var.location
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

module "subnet_creation" {
  source = "./modules/subnet"
  subnet-name = "${var.env_prefix}-subnet"
  rg-name = azurerm_resource_group.rgtf.name
  subent_cidr_block = var.subnet_cidr_block
  env_prefix = var.env_prefix
  vnet-name = azurerm_virtual_network.vnettf.name
}
module "vm_creation" {
  source = "./modules/webserver"
  env_prefix = var.env_prefix
  location = azurerm_resource_group.rgtf.location
  rg_name = azurerm_resource_group.rgtf.name
  subnet_id = module.subnet_creation.subneta.id
}