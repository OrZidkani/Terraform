terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.60.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  skip_provider_registration = true
}
resource "azurerm_resource_group" "management" {
  name     = "${var.prefix}_rg"
  location = var.location
  tags = {
    environment = var.tag_name
  }
}
resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }
  byte_length = 8
}
resource "azurerm_traffic_manager_profile" "traffic-manager" {
  name                   = random_id.server.hex
  resource_group_name    = azurerm_resource_group.management.name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = random_id.server.hex
    ttl           = 100
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"

  }

  tags = {
    environment = var.tag_name
  }
}

module "east" {
  source   = "./modules/resources"
  prefix   = "${var.prefix}-eastus"
  location = var.location
  username = var.vm_username
  password = var.vm_password
}

# Create Traffic Manager - East End Point
resource "azurerm_traffic_manager_endpoint" "tm-endpoint-east" {
  name                = "${var.prefix}-eastus"
  resource_group_name = azurerm_resource_group.management.name
  profile_name        = azurerm_traffic_manager_profile.traffic-manager.name
  type                = "azureEndpoints"
  target_resource_id  = module.east.public_ip_address_id
}



module "north" {
  source   = "./modules/resources"
  prefix   = "${var.prefix}-northeurope"
  location = var.north_location
  username = var.vm_username
  password = var.vm_password
}


# Create Traffic Manager - North End Point
resource "azurerm_traffic_manager_endpoint" "tm-endpoint-north" {
  name                = "${var.prefix}-northeurope"
  resource_group_name = azurerm_resource_group.management.name
  profile_name        = azurerm_traffic_manager_profile.traffic-manager.name
  type                = "azureEndpoints"
  target_resource_id  = module.north.public_ip_address_id
}