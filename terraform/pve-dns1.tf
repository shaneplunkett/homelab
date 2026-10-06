module "dns1" {
  source    = "./modules/nixos-lxc"
  hostname  = "dns1"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 1
  memory    = 1024
  disk_size = 8
}
