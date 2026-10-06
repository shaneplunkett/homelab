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
      }
    );
  };
}
