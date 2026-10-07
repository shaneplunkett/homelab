{
  description = "Homelab Flake";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    colmena = {
      url = "github:nix-community/colmena/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vex-brain = {
      url = "git+ssh://git@github.com/shaneplunkett/vex-brain";
      flake = false;
    };
  };
  outputs =
    {
      nixpkgs,
      colmena,
      agenix,
      vex-brain,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          # Official Cloudflare CLI (beta) isn't in nixpkgs yet, so run the
          # pinned npm release. Bump the version here when upgrading.
          cf = pkgs.writeShellScriptBin "cf" ''
            exec ${pkgs.nodejs_22}/bin/npx --yes cf@1.0.0-beta.12 "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              cf
              pkgs.cloudflared
              pkgs.wrangler
              pkgs.nodejs_22
              pkgs.dnsutils
              pkgs.doggo
              pkgs.jq
              pkgs.colmena
              agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
              pkgs.grafana-alloy
              pkgs.restic
              pkgs.rclone
            ];
          };
        }
      );

      nixosConfigurations = {
        base = nixpkgs.lib.nixosSystem {
          modules = [ ./modules/base.nix ];
        };

      };

      colmenaHive = colmena.lib.makeHive {
        meta.nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        meta.specialArgs = { inherit vex-brain; };
        defaults =
          {
            config,
            lib,
            name,
            ...
          }:
          {
            deployment.targetHost = lib.mkDefault (
              if config.homelab.tailscale.enable then name else config.homelab.lanAddress
            );
            imports = [
              ./modules/base.nix
              agenix.nixosModules.default
              ./modules/agenix
              ./modules/services/backup
              ./modules/services/alloy
              ./modules/services/tailscale
            ];
          };

        dashboard = {
          imports = [ ./modules/hosts/dashboard.nix ];
          homelab.lanAddress = "192.168.1.152";
        };

        monitoring = {
          imports = [ ./modules/hosts/monitoring.nix ];
          homelab.lanAddress = "192.168.1.78";
        };

        ingress = {
          imports = [ ./modules/hosts/ingress.nix ];
          homelab.lanAddress = "192.168.1.149";
        };

        dns1 = {
          imports = [ ./modules/hosts/dns.nix ];
          homelab.lanAddress = "192.168.1.91";
        };

        dns2 = {
          imports = [ ./modules/hosts/dns.nix ];
          homelab.lanAddress = "192.168.1.236";
        };

        plex = {
          imports = [ ./modules/hosts/plex.nix ];
          homelab.lanAddress = "192.168.1.237";
        };

        arr = {
          imports = [ ./modules/hosts/arr.nix ];
          homelab.lanAddress = "192.168.1.90";
        };

        brain = {
          imports = [ ./modules/hosts/brain.nix ];
          homelab.lanAddress = "192.168.1.243";
        };
      };
    };

}
