_: {
  services = {
    unbound = {
      enable = true;
      settings.server = {
        port = 5335;
        serve-expired = true;
      };

      localControlSocketPath = "/run/unbound/unbound.ctl";

    };

    prometheus.exporters.unbound = {
      enable = true;
      openFirewall = true;
      unbound = {
        host = "unix:///run/unbound/unbound.ctl";
        ca = null;
        certificate = null;
        key = null;
      };
    };
  };
}
