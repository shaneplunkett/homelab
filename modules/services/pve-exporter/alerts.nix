{
  lib,
  nodes,
  options,
  pkgs,
  ...
}:
let
  byThreshold = import ../prometheus/thresholds.nix { inherit lib nodes options; } "name";
in
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "pve.rules.json" (
      builtins.toJSON {
        groups = [
          {
            name = "pve";
            rules =
              byThreshold "disk" (
                { value, percent, matcher }:
                {
                  alert = "LxcDiskFilling";
                  expr = ''(pve_disk_usage_bytes / pve_disk_size_bytes) * on(id) group_left(name, node) pve_guest_info{type="lxc", ${matcher}} > ${toString value}'';
                  for = "10m";
                  labels.severity = "warning";
                  annotations = {
                    summary = "{{ $labels.name }} on {{ $labels.node }} is {{ $value | humanizePercentage }} full";
                    condition = "Root disk over ${percent} for 10m";
                    check = ''ssh {{ $labels.node }} sudo pct exec {{ reReplaceAll "^lxc/" "" $labels.id }} -- du -xh -d2 / | sort -h | tail'';
                  };
                }
              )
              ++ byThreshold "cpu" (
                { value, percent, matcher }:
                {
                  alert = "GuestCpuHigh";
                  expr = "pve_cpu_usage_ratio * on(id) group_left(name, node) pve_guest_info{${matcher}} > ${toString value}";
                  for = "15m";
                  labels.severity = "warning";
                  annotations = {
                    summary = "{{ $labels.name }} on {{ $labels.node }} is at {{ $value | humanizePercentage }} CPU";
                    condition = "CPU over ${percent} for 15m";
                    check = "ssh {{ $labels.node }} top -bn1 -c | head -20";
                  };
                }
              );
          }
        ];
      }
    ))
  ];
}
