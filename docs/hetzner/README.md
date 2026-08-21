# Hetzner Cloud

## Summary

Cloud infrastructure hosted on Hetzner, managed via Terraform (state in Terraform Cloud, applied locally via the terraform CLI).

| Resource    | Type        | Location  | Purpose                        |
|-------------|-------------|-----------|--------------------------------|
| hetzvps     | cax11 VPS   | Nuremberg | Tailscale exit node, NixOS     |
| backups     | bx11 Storage Box | Helsinki | Restic backup target      |

## Terraform

All resources defined in `terraform/hetzner.tf`. Provider token supplied via
`TF_VAR_hcloud_token` in the repo-root `.envrc`.

**Apply:** run `terraform plan` / `terraform apply` locally from `terraform/`.
The push-triggered GitHub Actions workflow (`infra.yml`) was removed 2026-08-21
ahead of a CI rework — applies are manual until that lands.

**Local plan:** requires the repo-root `.envrc` (direnv), including:
```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```
Without this, plan wants to destroy/recreate Hetzner resources.
