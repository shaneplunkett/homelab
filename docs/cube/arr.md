# Arr LXC

## Summary

Alpine LXC running the media automation stack in Docker. Media and appdata come from Unraid.

- **Container:** `terraform/cube-arr.tf`
- **Stack:** `stacks/cube/arr-lxc/arr/compose.yaml` (what runs, images, ports)
- **Management:** Hawser agent on the LXC (`terraform/modules/hawser`), driven from Dockhand

## Notes

- **Static IP on purpose.** The ingress routes in `modules/services/nginx-ingress` point straight at this container's address, so it can't move. Change the IP and you need to update the ingress too.
- **Storage is bind-mounted from Proxmox**, not mounted inside the LXC. The Unraid NFS shares are Proxmox storage pools on the host (see `docs/cube/README.md`); Terraform bind-mounts them in. `nesting=1` is there for Docker-in-LXC.
- **PUID 99 / PGID 100** match Unraid's `nobody:users`, so files written to the shares keep the permissions Unraid expects. Anything new that writes to the shares should use the same IDs.
- **MiniDLNA needs host networking.** DLNA discovery is multicast (SSDP), which doesn't make it through Docker's bridge network.
