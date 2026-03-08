resource "proxmox_virtual_environment_container" "arr" {
  node_name             = local.cube.name
  description           = "Arr Stack Container"
  unprivileged          = true
  environment_variables = {}
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
    cores        = 2
    units        = 1024
  }
  memory {
    dedicated = 4096
    swap      = 1024
  }
  disk {
    acl           = false
    datastore_id  = "local-lvm"
    mount_options = []
    quota         = false
    replicate     = false
    size          = 40
  }
  network_interface {
    bridge      = "vmbr0"
    enabled     = true
    firewall    = true
    mac_address = "BC:24:11:D0:E3:0D"
    mtu         = 0
    name        = "eth0"
    rate_limit  = 0
    vlan_id     = 0
  }
  initialization {
    entrypoint = null
    hostname   = "arr"

    ip_config {
      ipv4 {
        address = "192.168.1.90/24"
        gateway = "192.168.1.1"
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
  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/appdata"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = null
    volume        = "/mnt/pve/unraid-appdata"
  }
  mount_point {
    acl           = false
    backup        = false
    mount_options = []
    path          = "/mnt/programs"
    quota         = false
    read_only     = false
    replicate     = true
    shared        = false
    size          = null
    volume        = "/mnt/pve/unraid-programs"
  }
}
