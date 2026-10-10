_: {
  services = {
    unbound = {
      enable = true;
      settings = {
        server = {
          port = 5335;
          serve-expired = true;
          serve-expired-client-timeout = 0;
          prefetch = true;
          msg-cache-size = "32m";
          rrset-cache-size = "64m";
          infra-keep-probing = true;
        };
        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = true;
            forward-addr = [
              "9.9.9.9@853#dns.quad9.net"
              "149.112.112.112@853#dns.quad9.net"
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
            ];
          }
        ];
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
