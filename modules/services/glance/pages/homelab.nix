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
        (import ../widgets/releases)
      ];
    }
    {
      size = "small";
      widgets = [
        (import ../widgets/proxmox-ve-stats)
        (import ../widgets/unraid { inherit secrets; })
        (import ../widgets/dns { inherit nodes; })
        (import ../widgets/backups { inherit lib nodes; })
        (import ../widgets/alerts { inherit nodes; })
      ];
    }
  ];
}
