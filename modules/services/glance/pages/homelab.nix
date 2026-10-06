{ lib, nodes }:
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
        (import ../widgets/alerts { inherit nodes; })
      ];
    }
  ];
}
