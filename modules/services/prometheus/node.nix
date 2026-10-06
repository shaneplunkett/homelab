{
  nodes,
  lib,
  pkgs,
  ...
}:
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
                {
                  alert = "HostMemoryLow";
                  expr = "node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.10";
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "{{ $labels.host }} has only {{ $value | humanizePercentage }} memory free";
                }
              ];
            }
          ];
        }
      ))
    ];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = lib.mapAttrsToList (name: node: {
          targets = [ "${node.config.deployment.targetHost}:9100" ];
          labels.host = name;
        }) nodes;
      }
    ];
  };
}
