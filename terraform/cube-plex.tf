resource "proxmox_virtual_environment_container" "plex" {
  description   = "Plex Container"
  node_name     = local.cube.name
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
    type             = "ubuntu"
  }
  cpu {
    architecture = "amd64"
    cores        = 4
    units        = 1024
  }

  memory {
    dedicated = 8192
    swap      = 1024
  }

  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 150
  }

  network_interface {
    bridge      = "vmbr0"
    enabled     = true
    firewall    = true
    mac_address = "BC:24:11:AA:D1:7C"
    mtu         = 0
    name        = "eth0"
    rate_limit  = 0
    vlan_id     = 0
  }
  initialization {
    entrypoint = null
    hostname   = "plex"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/media"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = null
    volume        = "/mnt/pve/unraid-media"
  }
}
