{
  lib,
  nodes,
  secrets,
}:
{
  name = "Homelab";
  width = "wide";

  columns = [
    {
      size = "full";
      widgets = [
        (import ../widgets/services {
          inherit lib nodes;
          group = "homelab";
        })
        (import ../widgets/unraid { inherit secrets; })
      ];
    }
    {
      size = "small";
      widgets = [
        (import ../widgets/alerts { inherit nodes; })
        (import ../widgets/proxmox-ve-stats)
        (import ../widgets/releases)
        (import ../widgets/dns { inherit nodes; })
        (import ../widgets/backups { inherit lib nodes; })
      ];
    }
  ];
}
