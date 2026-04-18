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
        configs = import ./configs { inherit pkgs; };
        scripts = import ./scripts { inherit pkgs configs; };
      in
      {
        devShells.default = import ./shell.nix {
          inherit pkgs scripts;
        };

        packages = {
          default = scripts.misskeyEnv;
          nix-misskey = scripts.misskeyEnv;
        };

        apps.default = {
          type = "app";
          program = "${scripts.misskeyEnv}/bin/nix-misskey";
        };

        formatter = pkgs.nixfmt;
      }
    );
}
