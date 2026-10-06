# PVE

## Summary

Primary Proxmox host. It runs the experiments and heavier workloads, keeping
them away from the always-on services on Cube. Containers and VMs are declared
in `terraform/pve-*.tf`.

Per-service docs:

- [unraid.md](unraid.md)
- [mcphub.md](mcphub.md)
- [satisfactory.md](satisfactory.md)
- [technitium.md](technitium.md)
- [macos-tahoe.md](macos-tahoe.md)

## Gotchas

- Never copy-paste a `mac_address` from one container's Terraform to another.
  A duplicated MAC once had two containers fighting over the same DHCP lease.
