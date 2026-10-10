{
  homelab = {
    backup.paths = [ "/var/lib/private/matterjs-server" ];
    monitoring.units = [ "matterjs-server.service" ];
  };

  services.matterjs-server.enable = true;

  networking.firewall.allowedUDPPorts = [ 5540 ];
}
