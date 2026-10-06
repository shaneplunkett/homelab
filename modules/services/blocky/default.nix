{ nodes, ... }: {
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 53;
        http = 4000;
      };
      upstreams.groups.default = [ "127.0.0.1:5335" ];
      blocking = {
        denylists.ads = [
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
          "https://big.oisd.nl/domainswild"
        ];
        clientGroupsBlock.default = [ "ads" ];
        blockType = "nxDomain";
        loading.strategy = "fast";
      };
      customDNS = {
        mapping."shaneplunkett.com" = nodes.ingress.config.homelab.lanAddress;
        zone = ''
          $ORIGIN shaneplunkett.com.
          redbook 3600 CNAME red-book-5nn.pages.dev.
        '';
      };
      prometheus.enable = true;
      queryLog.type = "console";
    };
  };
  services.resolved.enable = false;
  networking.firewall = {
    allowedTCPPorts = [
      53
      4000
    ];
    allowedUDPPorts = [ 53 ];

  };
}
