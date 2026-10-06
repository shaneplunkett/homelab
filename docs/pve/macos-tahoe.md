# macOS Tahoe VM

> Rebuild recipe for a VM that isn't currently deployed. There's no Terraform for it, and its old VMID has been reused.

## Summary

macOS 26 Tahoe as a KVM VM on PVE. A headless server providing Apple services (iMessage, Mail, Shortcuts) through MCP servers that MCPHub connects to.

Everything inside the VM (auto-login, sleep prevention, MCP servers) is managed by nix-darwin: `hosts/darwin/macvm.nix` in the nix config repo.

## Setup Guide

This was painful to get right. If you're rebuilding, follow these steps exactly.

### Prerequisites

- Proxmox host with an AMD CPU
- LongQT OpenCore ISO, uploaded to Proxmox ISO storage

### Step 1: Download the macOS Installer

Use `macrecovery.py` from the OpenCore project to download the recovery image. The board ID picks which macOS version you get:

```bash
python3 macrecovery.py -b Mac-27AD2F918AE68F61 download
```

This downloads `BaseSystem.dmg` and `BaseSystem.chunklist`. Convert to ISO and upload to Proxmox, or attach the raw image as a second SATA disk.

### Step 2: Create the Proxmox VM

The settings that matter:

- **Machine:** q35
- **BIOS:** OVMF (UEFI) with `pre-enrolled-keys=0`. macOS doesn't use Secure Boot keys.
- **CPU:** `host`, overridden with:
  ```
  args: -cpu Skylake-Client-v4,vendor=GenuineIntel -device virtio-tablet
  ```
  This spoofs an Intel CPU so macOS will run on AMD. `virtio-tablet` gives an absolute pointer; set `tablet: 0` so the default one isn't added too.
- **Memory:** balloon off (`balloon: 0`). macOS doesn't support ballooning.
- **Disk:** SATA, not VirtIO. macOS has no VirtIO block driver. Turn on `discard` and `ssd` for TRIM.
- **Network:** VirtIO is fine. macOS does have a VirtIO net driver via OpenCore.
- **OS type:** Linux (`l26`). Proxmox has no macOS type and this works fine.
- **Display:** default. Use the noVNC console for initial setup.
- **QEMU guest agent:** enabled.

Mount the OpenCore ISO on `ide2` and leave it there permanently: it's the bootloader. Boot order is the SATA disk, then `ide2`.

### Step 3: Install macOS

1. Boot the VM. The OpenCore menu appears.
2. Select the macOS installer.
3. In Disk Utility, format the SATA disk as APFS.
4. Install macOS (takes a while, multiple reboots).
5. On each reboot, pick "macOS Installer" from the OpenCore menu until installation completes.
6. Finish the setup wizard and create user `shane`.

### Step 4: Install VMHide

VMHide is a kext that hides the hypervisor from macOS. It's critical for iCloud/iMessage, because Apple blocks those services on detected VMs.

After installing, check:

```bash
sysctl kern.hv_vmm_present
# Should return: kern.hv_vmm_present: 0
```

Without VMHide this returns `1` and iCloud refuses to activate.

VMHide replaces `kvm=off` in the Proxmox args. Don't use both: `kvm=off` disables KVM acceleration entirely and tanks performance.

### Step 5: Post-Install Configuration

Do these from the noVNC console, before SSH is available:

1. **Enable Remote Login:** System Settings → General → Sharing → Remote Login.
2. **Sign into iCloud:** System Settings → Apple ID. Needed for iMessage and Mail sync.
3. **Passwordless sudo:**
   ```bash
   sudo visudo
   # Add: shane ALL=(ALL) NOPASSWD: ALL
   ```
4. **Copy your SSH key:** `ssh-copy-id shane@<vm-ip>`

### Step 6: Install Nix and Apply Config

Once SSH works:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh
```

Then clone the nix config repo and apply the `macvm` host config (`hosts/darwin/macvm.nix`). That sets up auto-login, sleep prevention and the MCP servers.

### Step 7: Connect to MCPHub

MCPHub reaches the VM's MCP servers through `mcp-remote` entries in its `mcp_settings.json`. That's configured on the MCPHub side (see `docs/pve/mcphub.md`), not on this VM.

## Gotchas

- **SATA, not VirtIO, for the disk.** macOS has no VirtIO block driver. Use discard+ssd for TRIM.
- **Don't use `kvm=off`.** Use VMHide instead; `kvm=off` kills performance.
- **iCloud activation can fail** if VMHide isn't working or Apple flags the serial. Generate fresh SMBIOS serials with GenSMBIOS, which is on the OpenCore volume at `/Volumes/LongQT-OpenCore/GenSMBIOS`.
- **macOS updates can break VMHide.** You may need to reinstall the kext after a major update.
- **The OpenCore ISO must stay mounted.** It's the bootloader; the VM won't boot without it.
- **Auto-login is essential** for headless use. Without it macOS sits at the login screen after a reboot and none of the MCP servers start.
- **The memory warning is harmless.** The MacPro7,1 SMBIOS expects 12 DIMMs, which the VM can't emulate.
