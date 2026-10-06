module "dns2" {
  source    = "./modules/nixos-lxc"
  hostname  = "dns2"
  node_name = local.cube.name
  ip        = "dhcp"
  cores     = 1
  memory    = 1024
  disk_size = 8
}
