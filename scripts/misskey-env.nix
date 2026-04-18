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

  libDir = pkgs.runCommandLocal "nix-misskey-lib" { } ''
    mkdir -p $out
    install -m 644 ${./lib/common.sh}   $out/common.sh
    install -m 644 ${./lib/postgres.sh} $out/postgres.sh
    install -m 644 ${./lib/redis.sh}    $out/redis.sh
    install -m 644 ${./lib/config.sh}   $out/config.sh
    install -m 644 ${./lib/tests.sh}    $out/tests.sh
  '';

  rendered =
    builtins.replaceStrings
      [
        "@PG_CONF@"
        "@PG_HBA@"
        "@REDIS_CONF@"
        "@MISSKEY_DEFAULT@"
        "@MISSKEY_TEST@"
        "@PATH_PREFIX@"
        "@LIB_DIR@"
      ]
      [
        "${configs.postgres.conf}"
        "${configs.postgres.hba}"
        "${configs.redis}"
        "${configs.misskey.default}"
        "${configs.misskey.test}"
        pathPrefix
        "${libDir}"
      ]
      (builtins.readFile ./nix-misskey.sh);
in
pkgs.writeShellScriptBin "nix-misskey" rendered
