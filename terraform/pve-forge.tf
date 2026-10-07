module "forge" {
  source    = "./modules/nixos-lxc"
  hostname  = "forge"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 2
  memory    = 2048
  disk_size = 32
}
