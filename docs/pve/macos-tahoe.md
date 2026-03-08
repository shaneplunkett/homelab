# macOS Tahoe VM

## Summary

macOS 26 Tahoe running as a KVM virtual machine on the primary Proxmox node. Headless server providing Apple services (iMessage, Mail, Shortcuts) via MCP servers connected to MCPHub.

- **VMID:** 106
- **Name:** macos-tahoe
- **IP:** 192.168.1.205
- **macOS:** 26 Tahoe (26.3.1)
- **CPU:** 4 cores x 2 sockets (8 total)
- **RAM:** 16 GB (balloon disabled)
- **Disk:** 128 GB SATA on local-lvm (discard=on, ssd=1) + 1 GB SATA (installer)
- **Network:** virtio bridge (vmbr0)
- **QEMU Guest Agent:** enabled

## Proxmox Config

`/etc/pve/qemu-server/106.conf`:

```
agent: enabled=1
args: -cpu Skylake-Client-v4,vendor=GenuineIntel -device virtio-tablet
balloon: 0
bios: ovmf
boot: order=sata0;ide2
cores: 4
cpu: host
efidisk0: local-lvm:vm-106-disk-0,efitype=4m,pre-enrolled-keys=0,size=4M
ide2: local:iso/LongQT-OpenCore-v0.7.iso,media=cdrom,size=15512K
machine: q35
memory: 16384
meta: creation-qemu=9.2.0,ctime=1772794910
name: macos-tahoe
net0: virtio=BC:24:11:48:0A:E1,bridge=vmbr0
ostype: l26
sata0: local-lvm:vm-106-disk-1,discard=on,size=128G,ssd=1
sata1: local-lvm:vm-106-disk-2,size=1G
scsihw: virtio-scsi-pci
smbios1: uuid=7fe4673e-03d1-446c-83d2-a33a14e8249d
sockets: 2
tablet: 0
vmgenid: c6560175-fe21-4ceb-aa91-52dcbb099de1
```

Key config notes:
- `args: -cpu Skylake-Client-v4,vendor=GenuineIntel` — spoofs Intel CPU for macOS compatibility on AMD
- `-device virtio-tablet` — absolute pointer device (replaces tablet=0 default)
- `balloon: 0` — memory ballooning disabled (macOS doesn't support it)
- `boot: order=sata0;ide2` — boots main disk first, falls back to OpenCore ISO
- `ide2` — LongQT OpenCore v0.7 ISO mounted permanently as bootloader
- `pre-enrolled-keys=0` — no Secure Boot keys (macOS doesn't use them)

## What's Deployed

Services are managed by nix-darwin config at `hosts/darwin/macvm.nix` in the nix config repo. The nix config handles auto-login, sleep prevention, and MCP server deployment.

## Setup Guide

This was painful to get right. If you're rebuilding, follow these steps exactly.

### Prerequisites

- Proxmox VE host with AMD CPU (Ryzen 9 7900 confirmed working)
- LongQT OpenCore v0.7 ISO (upload to Proxmox ISO storage)

### Step 1: Download the macOS Installer

Use `macrecovery.py` from the OpenCore project to download the macOS recovery image:

```bash
python3 macrecovery.py -b Mac-27AD2F918AE68F61 download
```

This downloads `BaseSystem.dmg` and `BaseSystem.chunklist`. Convert to ISO and upload to Proxmox, or attach the raw image as a second SATA disk.

### Step 2: Create the Proxmox VM

Recreate with the config above. The important bits:

- **Machine:** q35
- **BIOS:** OVMF (UEFI), no Secure Boot keys
- **CPU:** host with args override to Skylake-Client-v4 + GenuineIntel vendor
- **Cores:** 4, **Sockets:** 2 (macOS sees 8 cores)
- **RAM:** 16384 MB, balloon OFF
- **Disk:** SATA (not VirtIO — macOS doesn't have VirtIO block drivers out of the box), 128 GB, discard+ssd
- **Network:** VirtIO (macOS does have VirtIO net drivers via OpenCore)
- **OS Type:** Linux (l26) — Proxmox doesn't have a macOS type, this works fine
- **Display:** default (use Proxmox noVNC console for initial setup)

Mount the LongQT OpenCore ISO on ide2 — this stays mounted permanently as the bootloader.

### Step 3: Install macOS

1. Boot the VM — OpenCore menu appears
2. Select the macOS installer
3. Open Disk Utility, format the SATA disk as APFS
4. Install macOS (takes a while, multiple reboots)
5. On each reboot, select "macOS Installer" from OpenCore menu until installation completes
6. Complete the setup wizard — create user `shane`

### Step 4: Install VMHide

VMHide 2.0.0 is a kext that hides the VM hypervisor status from macOS. Critical for iCloud/iMessage — Apple blocks these services on detected VMs.

After installation, verify:
```bash
sysctl kern.hv_vmm_present
# Should return: kern.hv_vmm_present: 0
```

Without VMHide, this returns `1` and iCloud services will refuse to activate.

**Important:** VMHide replaces the need for `kvm=off` in the Proxmox args. Do NOT use both — `kvm=off` disables KVM acceleration entirely and tanks performance. VMHide achieves the same goal (hiding hypervisor presence) without the performance penalty.

### Step 5: Post-Install Configuration

These need to be done via the Proxmox console (noVNC) before SSH is available:

1. **Enable Remote Login:** System Settings → General → Sharing → Remote Login → Enable
2. **Sign into iCloud:** System Settings → Apple ID → sign in. Needed for iMessage and Mail sync.
3. **Passwordless sudo:**
   ```bash
   sudo visudo
   # Add: shane ALL=(ALL) NOPASSWD: ALL
   ```
4. **Copy SSH key:**
   ```bash
   ssh-copy-id shane@192.168.1.205
   ```

### Step 6: Install Nix and Apply Config

Once SSH is working:

```bash
# Install nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh

# Clone nix config, apply macvm host config
# See hosts/darwin/macvm.nix in the nix config repo
```

The nix-darwin config handles:
- Auto-login (so the VM is usable after reboot without VNC)
- Sleep prevention (caffeinate / power management settings)
- MCP server deployment (apple-mail :8010, mac-messages :8011, applescript :8012, apple-shortcuts :8013)

### Step 7: Connect to MCPHub

The MCP servers on this VM are connected to MCPHub on the LXC (192.168.1.195) via `mcp-remote` entries in `mcp_settings.json`. This is configured on the MCPHub side, not on this VM.

## Gotchas

- **SATA not VirtIO for disk** — macOS doesn't have VirtIO block drivers. Use SATA with discard+ssd for TRIM support.
- **iCloud activation can fail** if VMHide isn't working or if Apple flags the serial number. May need to generate new SMBIOS serials using GenSMBIOS (available on the OpenCore volume at `/Volumes/LongQT-OpenCore/GenSMBIOS`).
- **Don't use `kvm=off`** — use VMHide instead. `kvm=off` kills performance.
- **Memory warning is harmless** — MacPro7,1 SMBIOS expects 12 DIMMs, VM can't emulate that.
- **OpenCore ISO must stay mounted** — it's the bootloader. The VM won't boot without it.
- **macOS updates can break VMHide** — may need to reinstall the kext after major updates.
- **Auto-login is essential** for headless operation — without it, macOS sits at the login screen after reboot and none of the MCP servers start.
