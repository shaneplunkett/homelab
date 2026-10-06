module "monitoring" {
  source    = "./modules/nixos-lxc"
  hostname  = "monitoring"
  node_name = local.cube.name
  ip        = "dhcp"
  cores     = 4
  memory    = 6144
  disk_size = 40
}
