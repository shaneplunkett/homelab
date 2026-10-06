module "dashboard" {
  source    = "./modules/nixos-lxc"
  hostname  = "dashboard"
  node_name = local.pve.name
  ip        = "dhcp"
}
