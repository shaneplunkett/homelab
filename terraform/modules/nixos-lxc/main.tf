resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = "Managed by Terraform"
  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot

  operating_system {
    template_file_id = var.template_file_id
    type             = "nixos"
  }

  console {
    enabled = true
    type    = "console"
  }

  cpu {
    architecture = "amd64"
    cores        = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    firewall    = true
    mac_address = var.mac_address
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.ip != "dhcp" ? var.gateway : null
      }
    }
  }

  features {
    nesting = true
  }

}
