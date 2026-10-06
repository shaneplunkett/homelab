{ lib, nodes }:
{
  name = "Media";
  width = "wide";

  columns = [
    {
      size = "full";
      widgets = [
        (import ../widgets/services {
          inherit lib nodes;
          group = "media";
        })
      ];
    }
  ];
}
