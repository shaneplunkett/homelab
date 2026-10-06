{ pkgs, ... }:
{
  services.prometheus.exporters.blackbox = {
    enable = true;
    configFile = pkgs.writeText "blackbox.json" (
      builtins.toJSON {
        modules.dns = {
          prober = "dns";
          dns = {
            query_name = "example.com";
            query_type = "A";
            valid_rcodes = [ "NOERROR" ];
          };
        };
        modules.ssh_banner = {
          prober = "tcp";
          tcp = {
            preferred_ip_protocol = "ip4";
            query_response = [ { expect = "^SSH-2.0-"; } ];
          };
        };
      }
    );
  };
}
