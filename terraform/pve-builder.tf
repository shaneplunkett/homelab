module "builder" {
  source    = "./modules/nixos-lxc"
  hostname  = "builder"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 8
  memory    = 16384
  swap      = 2048
  disk_size = 250
}
