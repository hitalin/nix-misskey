{
  description = "Misskey - An interplanetary microblogging platform 🚀";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodejs = pkgs.callPackage ./pkgs/nodejs.nix { inherit system; };
        pnpmShim = pkgs.writeShellScriptBin "pnpm" ''
          export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
          exec ${nodejs}/bin/corepack pnpm "$@"
        '';
        configs = import ./configs { inherit pkgs; };
        scripts = import ./scripts {
          inherit pkgs configs nodejs pnpmShim;
        };
      in
      {
        devShells.default = import ./shell.nix {
          inherit pkgs scripts nodejs pnpmShim;
        };

        packages = {
          default = scripts.misskeyEnv;
          nix-misskey = scripts.misskeyEnv;
          nodejs = nodejs;
        };

        apps.default = {
          type = "app";
          program = "${scripts.misskeyEnv}/bin/nix-misskey";
        };

        formatter = pkgs.nixfmt;
      }
    );
}
