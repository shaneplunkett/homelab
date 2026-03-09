# Hetzner Cloud

## Summary

Cloud infrastructure hosted on Hetzner, managed via Terraform (state in Terraform Cloud, applied via GitHub Actions).

| Resource    | Type        | Location  | Purpose                        |
|-------------|-------------|-----------|--------------------------------|
| hetzvps     | cax11 VPS   | Nuremberg | Tailscale exit node, NixOS     |
| backups     | bx11 Storage Box | Helsinki | Restic backup target      |

## Terraform

All resources defined in `terraform/hetzner.tf`. Provider token stored as `HCLOUD_TOKEN` in GitHub Actions secrets.

**Apply:** push to `main` with changes in `terraform/` — GitHub Actions runs plan + apply automatically.

**Local plan:** requires `.envrc` with:
```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```
Without this, plan wants to destroy/recreate Hetzner resources.
