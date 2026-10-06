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
  };
  outputs =
    {
      nixpkgs,
      colmena,
      agenix,
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
        defaults = {
          imports = [
            ./modules/base.nix
            agenix.nixosModules.default
            ./modules/agenix
          ];
        };
        #TODO: Figure out not using IPs for declaring targetHost
        dashboard = {
          imports = [ ./modules/hosts/dashboard.nix ];
          deployment.targetHost = "192.168.1.152";
        };

        monitoring = {
          imports = [ ./modules/hosts/monitoring.nix ];
          deployment.targetHost = "192.168.1.78";
        };
      };
    };

}
