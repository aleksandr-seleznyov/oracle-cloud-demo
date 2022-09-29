output "access-ip" {
  value = oci_network_load_balancer_network_load_balancer.access-nlb.ip_addresses.0.ip_address
}

output "applications-ip" {
  value = oci_load_balancer.applications-lb.ip_address_details.0.ip_address
}

output "test" {
  value = var.private_key
}