module "auth" {
  source    = "./modules/nixos-lxc"
  hostname  = "auth"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 1
  memory    = 1024
  disk_size = 8
}
