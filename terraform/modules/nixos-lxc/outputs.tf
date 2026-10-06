output "container_id" {
  value = proxmox_virtual_environment_container.this.vm_id
}

output "ipv4_address" {
  value = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address
}

output "hostname" {
  value = var.hostname
}
