module "dockhand" {
  source         = "./modules/alpine-lxc"
  hostname       = "dockhand"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  ip             = "dhcp"
  cores          = 2
  memory         = 2048
  disk_size      = 16
  nesting        = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
