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

  lifecycle {
    ignore_changes = [device_passthrough, mount_point]
  }
}

# Proxmox only lets root@pam set devices and bind mounts, and the API token
# is refused, so these go over SSH with pct instead. The container reboots
# to pick them up.

locals {
  root_only = concat(
    [for i, d in var.devices : "-dev${i} ${d.path}${d.gid != null ? ",gid=${d.gid}" : ""}"],
    [for i, path in keys(var.bind_mounts) : "-mp${i} ${var.bind_mounts[path]},mp=${path}"],
  )
}

resource "terraform_data" "root_only" {
  count = length(local.root_only) > 0 ? 1 : 0

  triggers_replace = {
    node_ip  = var.node_ip
    vm_id    = proxmox_virtual_environment_container.this.vm_id
    settings = local.root_only
  }

  lifecycle {
    precondition {
      condition     = var.node_ip != null
      error_message = "devices and bind_mounts need node_ip to SSH to the node."
    }
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no shane@${var.node_ip} 'sudo pct set ${self.triggers_replace.vm_id} ${join(" ", local.root_only)} && sudo pct reboot ${self.triggers_replace.vm_id}'"
  }
}
