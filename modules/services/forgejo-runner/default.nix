{
  config,
  pkgs,
  nodes,
  ...
}:
let
  unit = "forgejo-runner-builder";
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
      config.nix.package
      pkgs.colmena
    ];
  };

  systemd.services.${unit}.serviceConfig.LoadCredential = [
    "ssh-key:${config.age.secrets.builder-ssh-key.path}"
  ];

  programs.ssh = {
    knownHosts.forge.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKThjQG7Etu9AY90bUyg/ggLa80OexaSh0NzGDQB2E6k";
    extraConfig = ''
      Host forge
        IdentityFile /run/credentials/${unit}.service/ssh-key
    '';
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
