module "satisfactory" {
  source         = "./modules/alpine-lxc"
  hostname       = "satisfactory"
  node_name      = local.pve.name
  node_ip        = local.pve.ip
  vm_id          = 106
  ip             = "dhcp"
  mac_address    = "BC:24:11:81:EA:CC"
  cores          = 6
  memory         = 24576
  swap           = 4096
  disk_size      = 50
  nesting        = true
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_ed25519.pub")
}
