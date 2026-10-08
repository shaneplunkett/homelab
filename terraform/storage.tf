resource "proxmox_storage_nfs" "unraid_media" {
  id      = "unraid-media"
  server  = "192.168.1.132"
  export  = "/mnt/user/Media"
  content = ["images"]
  options = "soft,nofail"
}


resource "proxmox_storage_nfs" "unraid_appdata" {
  id      = "unraid-appdata"
  server  = "192.168.1.132"
  export  = "/mnt/user/appdata"
  content = ["images"]
  options = "soft,nofail"
}


resource "proxmox_storage_nfs" "unraid_programs" {
  id      = "unraid-programs"
  server  = "192.168.1.132"
  export  = "/mnt/user/Programs"
  content = ["images"]
  options = "soft,nofail"
}

moved {
  from = proxmox_virtual_environment_storage_nfs.unraid_media
  to   = proxmox_storage_nfs.unraid_media
}

moved {
  from = proxmox_virtual_environment_storage_nfs.unraid_appdata
  to   = proxmox_storage_nfs.unraid_appdata
}

moved {
  from = proxmox_virtual_environment_storage_nfs.unraid_programs
  to   = proxmox_storage_nfs.unraid_programs
}

resource "proxmox_storage_lvmthin" "cube_nvme" {
  id           = "nvme-thin"
  volume_group = "nvme"
  thin_pool    = "nvme"
  content      = ["images", "rootdir"]
  nodes        = [local.cube.name]
}
