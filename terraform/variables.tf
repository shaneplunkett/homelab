variable "pve_api_token" {
  type      = string
  sensitive = true
}

variable "pve_ip" {
  type    = string
  default = "192.168.1.169"
}

variable "cube_ip" {
  type    = string
  default = "192.168.1.238"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}
