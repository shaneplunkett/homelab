{ config, lib, ... }:
{

  options.homelab.secrets = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Names of agenix secrets for host usage from mdules/agenix/.";
  };

  config.age.secrets = lib.genAttrs config.homelab.secrets (name: {
    file = ./${name}.age;
  });

}
