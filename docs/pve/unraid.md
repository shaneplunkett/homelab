# Unraid VM

## Summary

Unraid server running as a VM on PVE, declared in `terraform/pve-unraid.tf`.

## PCIe Passthrough

Two devices are passed through to Unraid (the bus IDs are in the Terraform):

- **NVMe SSD**: fast cache/storage
- **SAS HBA**: gives Unraid direct access to any drives connected to it

## Notes

- Boots from USB, because the Unraid licence key lives on the USB stick
- Uses an `e1000` network adapter (not virtio), because Unraid's boot environment needs it
