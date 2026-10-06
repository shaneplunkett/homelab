module "ingress" {
  source    = "./modules/nixos-lxc"
  hostname  = "ingress"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 1
  memory    = 1024
  disk_size = 8
}
