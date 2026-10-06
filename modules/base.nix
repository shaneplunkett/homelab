{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  options.homelab.lanAddress = lib.mkOption {
    type = lib.types.str;
    description = "The host's LAN address, for anything that must keep working without Tailscale.";
  };

  config = {
    nixpkgs.hostPlatform = "x86_64-linux"; # the LXCs' platform

    nixpkgs.config.allowUnfree = true;
    nix.optimise.automatic = true;

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfq31bP+xQwlO/joZeGU6LaLYZXV2ql7TLSv5ToVUtJ"
    ];

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    services.prometheus = {
      exporters.node = {
        enable = true;
        openFirewall = true;
      };
    };

    system.stateVersion = "26.11";
  };
}
