module "brain" {
  source    = "./modules/nixos-lxc"
  hostname  = "brain"
  node_name = local.pve.name
  ip        = "dhcp"
  cores     = 4
  memory    = 8192
  swap      = 2048
  disk_size = 64
}
