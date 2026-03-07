# Unraid VM

## Summary

Unraid server running as a VM on the primary Proxmox node with PCIe passthrough for NVMe storage and a SAS HBA.

- **VMID:** 100
- **Name:** Unraid
- **CPU:** 4 cores, x86-64-v2-AES
- **RAM:** 4 GB (balloon disabled)
- **Boot:** USB passthrough (host device 5-2)
- **Network:** e1000 bridge (vmbr0, firewall enabled)

## Proxmox Config

`/etc/pve/qemu-server/100.conf`:

```
balloon: 0
bios: ovmf
boot: order=usb0
cores: 4
cpu: x86-64-v2-AES
efidisk0: local-lvm:vm-100-disk-1,efitype=4m,pre-enrolled-keys=1,size=4M
hostpci1: 0000:01:00
hostpci2: 0000:04:00.0
ide2: none,media=cdrom
machine: q35
memory: 4096
meta: creation-qemu=9.2.0,ctime=1747642156
name: Unraid
net0: e1000=BC:24:11:D7:EF:B5,bridge=vmbr0,firewall=1
numa: 0
ostype: l26
scsihw: virtio-scsi-single
smbios1: uuid=8f769e97-e7e1-4d73-8e22-1b25fc998966
sockets: 1
unused0: local-lvm:vm-100-disk-0
usb0: host=5-2
vmgenid: 81735f34-2e61-438f-a4d4-67f15f04e8a7
```

## PCIe Passthrough

Two devices passed through to Unraid:

- **`0000:01:00`** — Kingston NV2 NVMe SSD (SM2267XT, DRAM-less)
- **`0000:04:00.0`** — Broadcom/LSI SAS2008 HBA (Fusion-MPT SAS-2 Falcon)

The SAS HBA gives Unraid direct access to any drives connected to it. The NVMe SSD provides fast cache/storage.

## Notes

- Boots from USB (`boot: order=usb0`) — the Unraid licence key is on the USB stick
- Uses `e1000` network adapter (not virtio) — Unraid's boot environment needs this
- `cpu: x86-64-v2-AES` — generic CPU type with AES support, doesn't need host passthrough
- `balloon: 0` — memory ballooning disabled
- `unused0: local-lvm:vm-100-disk-0` — unused disk from initial setup, can be removed
