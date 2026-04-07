module "sftp" {
  source         = "./modules/alpine-lxc"
  hostname       = "sftp"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  ip             = "dhcp"
  cores          = 1
  memory         = 256
  disk_size      = 8
  tailscale      = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
