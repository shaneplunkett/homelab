{
  nodes,
  lib,
  options,
  pkgs,
  ...
}:
let
  byThreshold = import ./thresholds.nix { inherit lib nodes options; } "host";
  monitored = lib.filterAttrs (_: node: node.config.homelab.monitoring.enable) nodes;
in
{
  services.prometheus = {
    ruleFiles = [
      (pkgs.writeText "node.rules.json" (
        builtins.toJSON {
          groups = [
            {
              name = "node";
              rules = [
                {
                  alert = "HostDown";
                  expr = ''up{job="node"} == 0'';
                  for = "5m";
                  labels.severity = "critical";
                  annotations.summary = "{{ $labels.host }} isn't answering";
                }
              ]
              ++ byThreshold "memoryAvailable" (
                { value, matcher }:
                {
                  alert = "HostMemoryLow";
                  expr = "node_memory_MemAvailable_bytes{${matcher}} / node_memory_MemTotal_bytes < ${toString value}";
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.host }} has only {{ $value | humanizePercentage }} memory free";
                }
              );
            }
          ];
        }
      ))
    ];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = lib.mapAttrsToList (name: node: {
          targets = [ "${node.config.homelab.lanAddress}:9100" ];
          labels.host = name;
        }) monitored;
      }
    ];
  };
}
