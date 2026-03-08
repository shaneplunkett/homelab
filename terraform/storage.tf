resource "proxmox_virtual_environment_storage_nfs" "unraid_media" {
  id      = "unraid-media"
  server  = "192.168.1.132"
  export  = "/mnt/user/Media"
  content = ["backup"]
  options = "soft,nofail"
}


resource "proxmox_virtual_environment_storage_nfs" "unraid_appdata" {
  id      = "unraid-appdata"
  server  = "192.168.1.132"
  export  = "/mnt/user/appdata"
  content = ["backup"]
  options = "soft,nofail"
}


resource "proxmox_virtual_environment_storage_nfs" "unraid_programs" {
  id      = "unraid-programs"
  server  = "192.168.1.132"
  export  = "/mnt/user/Programs"
  content = ["backup"]
  options = "soft,nofail"
}
