module "home" {
  source      = "./modules/nixos-lxc"
  hostname    = "home"
  node_name   = local.pve.name
  ip          = "dhcp"
  mac_address = "BC:24:11:21:E0:4E"
  cores       = 2
  memory      = 2048
  disk_size   = 16
}
