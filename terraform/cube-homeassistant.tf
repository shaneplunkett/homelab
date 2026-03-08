module "home-assistant" {
  source    = "./modules/alpine-lxc"
  hostname  = "home-assistant"
  node_name = local.cube.name
  ip        = "dhcp"
  cores     = 2
  memory    = 4096
  disk_size = 16
  nesting   = true
}
