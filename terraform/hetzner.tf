resource "hcloud_ssh_key" "my_key" {
  name       = "hetzvps"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "hetzvps" {
  name        = "hetzvps"
  image       = "ubuntu-24.04"
  server_type = "cax11"
  location    = "nbg1"
  user_data   = <<-EOF
    #!/bin/bash
    curl -L https://github.com/elitak/nixos-infect/raw/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-24.11 bash 2>&1 | tee /tmp/infect.log
  EOF
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.my_key.id
  ]
}

resource "hcloud_storage_box" "backups" {
  name             = "backups"
  storage_box_type = "bx11"
  location         = "hel1"
  password         = random_password.storage_box.result

  access_settings = {
    reachable_externally = true
    samba_enabled        = false
    ssh_enabled          = true
    webdav_enabled       = false
    zfs_enabled          = true
  }

  snapshot_plan = {
    max_snapshots = 10
    minute        = 16
    hour          = 18
    day_of_week   = 3
  }

  ssh_keys = [
    var.ssh_public_key
  ]

  lifecycle {
    ignore_changes = [
      ssh_keys
    ]

    prevent_destroy = true
  }
  delete_protection = true
}

resource "random_password" "storage_box" {
  length  = 32
  special = true
}
