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
      "forge-bot-token"
      "terraform-cloud-token"
      "terraform-pve-token"
      "terraform-hcloud-token"
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
      pkgs.jq
      pkgs.nodejs
      config.programs.ssh.package
      config.nix.package
      pkgs.colmena
      pkgs.terraform
    ];
  };

  systemd.services.${unit}.serviceConfig.LoadCredential = [
    "ssh-key:${config.age.secrets.builder-ssh-key.path}"
    "forge-bot-token:${config.age.secrets.forge-bot-token.path}"
    "terraform-cloud-token:${config.age.secrets.terraform-cloud-token.path}"
    "terraform-pve-token:${config.age.secrets.terraform-pve-token.path}"
    "terraform-hcloud-token:${config.age.secrets.terraform-hcloud-token.path}"
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
    '') (lib.attrNames nodes)
    + ''
      Host 192.168.1.169 192.168.1.238
        User shane
        IdentityFile /run/credentials/${unit}.service/ssh-key
    '';
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
