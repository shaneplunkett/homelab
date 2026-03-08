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
