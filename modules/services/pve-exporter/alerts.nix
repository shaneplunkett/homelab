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
                { value, matcher }:
                {
                  alert = "LxcDiskFilling";
                  expr = ''(pve_disk_usage_bytes / pve_disk_size_bytes) * on(id) group_left(name, node) pve_guest_info{type="lxc", ${matcher}} > ${toString value}'';
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.name }} on {{ $labels.node }} is {{ $value | humanizePercentage }} full";
                }
              )
              ++ byThreshold "cpu" (
                { value, matcher }:
                {
                  alert = "GuestCpuHigh";
                  expr = "pve_cpu_usage_ratio * on(id) group_left(name, node) pve_guest_info{${matcher}} > ${toString value}";
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.name }} on {{ $labels.node }} has been at {{ $value | humanizePercentage }} CPU for 15 minutes";
                }
              );
          }
        ];
      }
    ))
  ];
}
