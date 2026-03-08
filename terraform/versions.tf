terraform {
  required_version = ">=1.5.0"
  cloud {

    organization = "metrokitten"

    workspaces {
      name = "homelab"
    }
  }
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.69.0"
    }
  }
}
