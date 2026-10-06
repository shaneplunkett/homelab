{ nodes, lib, ... }: {
  services.prometheus = {
    enable = true;
    retentionTime = "30d";
    extraFlags = [ "--storage.tsdb.retention.size=12GB" ];
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = lib.mapAttrsToList (_: node: "${node.config.deployment.targetHost}:9100") nodes;
          }
        ];
      }
    ];
  };
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
