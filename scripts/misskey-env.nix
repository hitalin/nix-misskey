{ pkgs, configs }:

let
  pathPrefix = pkgs.lib.makeBinPath (
    with pkgs;
    [
      nodejs_22
      pnpm
      postgresql_15
      redis
      git
      coreutils
      gnugrep
      gnused
      gawk
    ]
  );

  rendered =
    builtins.replaceStrings
      [
        "@PG_CONF@"
        "@PG_HBA@"
        "@REDIS_CONF@"
        "@MISSKEY_DEFAULT@"
        "@MISSKEY_TEST@"
        "@PATH_PREFIX@"
      ]
      [
        "${configs.postgres.conf}"
        "${configs.postgres.hba}"
        "${configs.redis}"
        "${configs.misskey.default}"
        "${configs.misskey.test}"
        pathPrefix
      ]
      (builtins.readFile ./nix-misskey.sh);
in
pkgs.writeShellScriptBin "nix-misskey" rendered
