output "east_public_ip" {
  value = module.east.public_ip_address
}

output "north_public_ip" {
  value = module.north.public_ip_address
}

output "traffic_manager_url" {
  value = azurerm_traffic_manager_profile.traffic-manager.fqdn
}
