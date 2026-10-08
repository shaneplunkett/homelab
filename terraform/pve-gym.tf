module "gym" {
  source      = "./modules/nixos-lxc"
  hostname    = "gym"
  node_name   = local.pve.name
  ip          = "dhcp"
  mac_address = "BC:24:11:C4:3F:EC"
  cores       = 1
  memory      = 1024
}
