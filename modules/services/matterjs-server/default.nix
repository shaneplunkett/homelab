{
  homelab = {
    backup.paths = [ "/var/lib/private/matterjs-server" ];
    monitoring.units = [ "matterjs-server.service" ];
  };

  services.matterjs-server = {
    enable = true;
    extraArgs = [ "--primary-interface=eth1" ];
  };

  networking.firewall.allowedUDPPorts = [ 5540 ];
}
