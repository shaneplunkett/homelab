# Baseline config for every Alpine LXC, including ones that predate
# alpine-lxc. Re-runs whenever the script changes, so edits here reach
# existing containers on the next apply.

locals {
  provision_script = <<-SCRIPT
set -e

# Point the stable repos at alpine_branch (tagged repos like
# @edge-community are left alone). On a change, upgrade to the new
# release; the container then needs a reboot to finish the move.
repos_before="$(cat /etc/apk/repositories)"
sed -i -E 's#/alpine/v[0-9]+[.][0-9]+/(main|community)$#/alpine/${var.alpine_branch}/\1#' /etc/apk/repositories
if ! grep -q '^[^#@]*/alpine/${var.alpine_branch}/main$' /etc/apk/repositories; then
  echo "no ${var.alpine_branch}/main repo in /etc/apk/repositories" >&2
  exit 1
fi
if [ "$repos_before" != "$(cat /etc/apk/repositories)" ]; then
  apk update -q
  apk upgrade --available
fi

# Nightly `apk -U upgrade` (after a random delay of up to 2h) via the
# official apk-cron job
apk add --no-cache apk-cron
rc-update add crond default
rc-service crond start 2>/dev/null || true

# Hand-rolled duplicates of the apk-cron job (alpine-lxc used to write
# apk-update; mcphub had its own auto-upgrade)
rm -f /etc/periodic/daily/apk-update /etc/periodic/daily/auto-upgrade
SCRIPT
}

resource "terraform_data" "baseline" {
  triggers_replace = {
    node_ip = var.node_ip
    vm_id   = var.vm_id
    script  = sha256(local.provision_script)
  }

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no shane@${var.node_ip} 'echo ${base64encode(local.provision_script)} | base64 -d | sudo pct exec ${var.vm_id} -- sh -s'"
  }
}
