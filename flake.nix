{
  description = "Homelab Flake";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    colmena.url = "github:nix-community/colmena/v0.5.0";

  };
  outputs =
    { nixpkgs, colmena, ... }:
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
            ];
          };
        }
      );

      nixosConfigurations = {
        base = nixpkgs.lib.nixosSystem {
          modules = [ ./modules/base.nix ];
        };

        colmenaHive = colmena.lib.makeHive {
          defaults = {
            imports = [ ./modules/base.nix ];
          };
          #TODO: Figure out not using IPs for declaring targetHost
          dashboard = {
            imports = [ ./modules/hosts/dashboard.nix ];
            deployment.targetHost = "192.168.1.152";
          };
        };
      };
    };

}
