module "home-automation" {
  source         = "./modules/alpine-lxc"
  hostname       = "home-automation"
  node_name      = local.cube.name
  node_ip        = local.cube.ip
  ip             = "dhcp"
  cores          = 2
  memory         = 2048
  disk_size      = 16
  nesting        = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
