# hetzvps

## Summary

ARM VPS running NixOS as a Tailscale exit node. Provisioned via Terraform with nixos-infect, configured via nix-config flake.

- **Server type:** cax11 (2 vCPU ARM, 4 GB RAM, 40 GB disk)
- **Location:** Nuremberg (nbg1)
- **OS:** NixOS (aarch64-linux)
- **Flake target:** `.#hetzvps`

## NixOS Config

Lives in `nix-config/hosts/hetzvps/`:

| File | Purpose |
|------|---------|
| `configuration.nix` | Main config — imports hardware, networking, modules |
| `hardware-configuration.nix` | GRUB EFI, qemu-guest, ext4 root |
| `networking-hetzner.nix` | Static IPs from nixos-infect (never use DHCP on Hetzner) |
| `modules/networking.nix` | Firewall + IP forwarding for Tailscale exit node |
| `modules/packages.nix` | Minimal server packages |
| `modules/services.nix` | Tailscale (exit node), OpenSSH, agenix, user config |

Home-manager config: `nix-config/home/shane/homelinuxserver.nix` — vanilla neovim, fish, tmux, starship, btop, git.

## Deploy

After nixos-infect finishes on a fresh server:

```bash
# SSH in as root
ssh root@<server-ip>

# Clone the config
nix-shell -p git --run 'git clone <nix-config-repo> /home/shane/nix-config'

# Rebuild with nohup (MUST use nohup/screen — SSH drops during network restart)
nohup bash -c 'nixos-rebuild switch --flake /home/shane/nix-config#hetzvps 2>&1 | tee /tmp/rebuild.log' &>/dev/null &

# Monitor progress
tail -f /tmp/rebuild.log
```

## If the server is recreated

New server means new identifiers. Update these in `nix-config`:

1. **`networking-hetzner.nix`** — pull from `/etc/nixos/networking.nix` on the new server (MAC + link-local change)
2. **`hardware-configuration.nix`** — check EFI partition UUID
3. **`secrets/secrets.nix`** — update hetzvps host key
4. **Rekey agenix secrets**

## Gotchas

- **Never use `networking.useDHCP = true`** — Hetzner uses routed static IPs (/32 prefix). Must use the infect-generated static networking config.
- **Always rebuild via nohup or screen** — `nixos-rebuild switch` restarts networking, which kills a bare SSH session mid-activation and can leave the system in a broken state.
- **Authorized keys must be in nix config** — the flake manages `/etc/ssh/authorized_keys.d/`. Without `openssh.authorizedKeys` declared, you get locked out after rebuild.
- **Tailscale auth key** — if the key was created as "ephemeral" in the Tailscale admin console, the node will be removed when it goes offline. Use a non-ephemeral key for a permanent VPS.
