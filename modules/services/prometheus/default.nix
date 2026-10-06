{ nodes, lib, ... }: {
  services.prometheus = {
    enable = true;
    retentionTime = "30d";
    extraFlags = [ "--storage.tsdb.retention.size=12GB" ];
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
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
