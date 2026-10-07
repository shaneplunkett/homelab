{
  config,
  lib,
  pkgs,
  nodes,
  ...
}:
let
  unit = "forgejo-runner-builder";
  lanAddress = name: nodes.${name}.config.homelab.lanAddress;
in
{
  homelab = {
    secrets = [
      "forgejo-runner-secret"
      "builder-ssh-key"
    ];
    monitoring.units = [ "${unit}.service" ];
  };

  services.forgejo-runner.instances.builder = {
    enable = true;
    settings = {
      runner.labels = [ "nix:host" ];
      server.connections.forge = {
        url = nodes.forge.config.services.forgejo.settings.server.ROOT_URL;
        uuid = "30653033-3932-6431-3831-386539343732";
      };
    };
    secrets.server.connections.forge.token_url = config.age.secrets.forgejo-runner-secret.path;
    hostPackages = [
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.gawk
      pkgs.gnused
      pkgs.nodejs
      config.programs.ssh.package
      config.nix.package
      pkgs.colmena
    ];
  };

  systemd.services.${unit}.serviceConfig.LoadCredential = [
    "ssh-key:${config.age.secrets.builder-ssh-key.path}"
  ];

  programs.ssh = {
    knownHosts = lib.mapAttrs (name: publicKey: {
      hostNames = [
        name
        (lanAddress name)
      ];
      inherit publicKey;
    }) (import ../../agenix/host-keys.nix);
    extraConfig = lib.concatMapStrings (name: ''
      Host ${name}
        HostName ${lanAddress name}
        IdentityFile /run/credentials/${unit}.service/ssh-key
    '') (lib.attrNames nodes);
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
