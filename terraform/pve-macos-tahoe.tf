resource "proxmox_virtual_environment_vm" "macos-tahoe" {
  name          = "macos-tahoe"
  description   = "macOS Tahoe — Apple MCP servers"
  node_name     = local.pve.name
  vm_id         = 106
  bios          = "ovmf"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-pci"
  boot_order    = ["sata0", "ide2"]
  kvm_arguments = "-cpu Skylake-Client-v4,vendor=GenuineIntel -device virtio-tablet"
  tablet_device = false
  started       = true

  agent {
    enabled = false
  }

  cpu {
    cores   = 4
    sockets = 2
    type    = "host"
  }

  memory {
    dedicated = 24576
  }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    pre_enrolled_keys = false
    type              = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "sata0"
    file_format  = "raw"
    size         = 128
    discard      = "on"
    ssd          = true
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "sata1"
    file_format  = "raw"
    size         = 1
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:48:0A:E1"
    model       = "virtio"
  }

  operating_system {
    type = "l26"
  }
}
