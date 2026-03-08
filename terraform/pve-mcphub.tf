resource "proxmox_virtual_environment_container" "mcphub" {
  description   = "MCP Host"
  node_name     = local.pve.name
  start_on_boot = true
  unprivileged  = false
  lifecycle {
    ignore_changes = [operating_system[0].template_file_id]
  }
  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  operating_system {
    template_file_id = "local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz"
    type             = "alpine"
  }
  cpu {
    architecture = "amd64"
    cores        = 4
    units        = 1024
  }

  memory {
    dedicated = 6144
    swap      = 2048
  }

  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 32
  }

  network_interface {
    bridge      = "vmbr0"
    enabled     = true
    firewall    = false
    mac_address = "BC:24:11:83:6C:69"
    mtu         = 0
    name        = "eth0"
    rate_limit  = 0
    vlan_id     = 0
  }
  initialization {
    entrypoint = null
    hostname   = "mcphub"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

