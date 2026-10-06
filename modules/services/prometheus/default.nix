{ ... }: {
  imports = [ ./node.nix ];

  services.prometheus = {
    enable = true;
    retentionTime = "30d";
    extraFlags = [ "--storage.tsdb.retention.size=12GB" ];
  };
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
