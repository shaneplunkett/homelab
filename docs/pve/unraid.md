# Unraid VM

## Summary

Unraid server running as a VM on PVE, declared in `terraform/pve-unraid.tf`.

## PCIe Passthrough

Two devices are passed through to Unraid (the bus IDs are in the Terraform):

- **NVMe SSD**: fast cache/storage
- **SAS HBA**: gives Unraid direct access to any drives connected to it

## Updates

Unraid checks weekly for OS and plugin updates and posts them to the homelab
alerts channel through its own Discord webhook, set up under Settings,
Notification Settings, Notification Agents. Updates are applied from its UI.
The notification grid has to have Agents ticked for Notices, Warnings and
Alerts, or Unraid finds updates but never tells Discord.

## Notes

- Boots from USB, because the Unraid licence key lives on the USB stick
- Uses an `e1000` network adapter (not virtio), because Unraid's boot environment needs it
- The array starts by itself (Disk Settings, Enable auto start), so a PVE
  reboot doesn't leave the shares unavailable
