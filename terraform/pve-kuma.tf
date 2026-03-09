module "uptime-kuma" {
  source         = "./modules/alpine-lxc"
  hostname       = "uptime-kuma"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  ip             = "dhcp"
  cores          = 1
  memory         = 512
  disk_size      = 8
  nesting        = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
