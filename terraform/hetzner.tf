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
