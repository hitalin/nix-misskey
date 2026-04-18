{
  pkgs,
  configs,
  nodejs,
  pnpmShim,
}:

let
  lib = pkgs.lib;

  runtimeInputs =
    [
      nodejs
      pnpmShim
    ]
    ++ (with pkgs; [
      postgresql_15
      redis
      git
      coreutils
      gnugrep
      gnused
      gawk
    ]);

  libDir = pkgs.runCommandLocal "nix-misskey-lib" { } ''
    mkdir -p $out
    install -m 644 ${./lib/env.sh}      $out/env.sh
    install -m 644 ${./lib/log.sh}      $out/log.sh
    install -m 644 ${./lib/repo.sh}     $out/repo.sh
    install -m 644 ${./lib/postgres.sh} $out/postgres.sh
    install -m 644 ${./lib/redis.sh}    $out/redis.sh
    install -m 644 ${./lib/config.sh}   $out/config.sh
    install -m 644 ${./lib/cmd.sh}      $out/cmd.sh
    install -m 644 ${./lib/tests.sh}    $out/tests.sh
  '';

  # Shared header injected at the top of every sub-command.
  # Defines config paths and sources every library module.
  header = ''
    PG_CONF='${configs.postgres.conf}'
    PG_HBA='${configs.postgres.hba}'
    REDIS_CONF='${configs.redis}'
    MISSKEY_DEFAULT='${configs.misskey.default}'
    MISSKEY_TEST='${configs.misskey.test}'
    LIB_DIR='${libDir}'

    # shellcheck source=/dev/null
    . "$LIB_DIR/env.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/log.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/repo.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/postgres.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/redis.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/config.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/cmd.sh"
    # shellcheck source=/dev/null
    . "$LIB_DIR/tests.sh"

  '';

  mkCmd =
    name: bodyFile:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = header + builtins.readFile bodyFile;
      excludeShellChecks = [
        "SC2034" # variables in header may be unused by a given sub-command
      ];
    };

  # name -> source file
  binSpecs = {
    "nix-misskey-app-setup" = ./bin/app-setup.sh;
    "nix-misskey-app-dev" = ./bin/app-dev.sh;
    "nix-misskey-app-build" = ./bin/app-build.sh;
    "nix-misskey-app-migrate" = ./bin/app-migrate.sh;
    "nix-misskey-db-init" = ./bin/db-init.sh;
    "nix-misskey-db-start" = ./bin/db-start.sh;
    "nix-misskey-db-stop" = ./bin/db-stop.sh;
    "nix-misskey-db-psql" = ./bin/db-psql.sh;
    "nix-misskey-cache-init" = ./bin/cache-init.sh;
    "nix-misskey-cache-start" = ./bin/cache-start.sh;
    "nix-misskey-cache-stop" = ./bin/cache-stop.sh;
    "nix-misskey-cache-cli" = ./bin/cache-cli.sh;
    "nix-misskey-status" = ./bin/status.sh;
    "nix-misskey-stop" = ./bin/stop.sh;
    "nix-misskey-clean" = ./bin/clean.sh;
    "nix-misskey-reset" = ./bin/reset.sh;
    "nix-misskey-logs" = ./bin/logs.sh;
    "nix-misskey-test-unit" = ./bin/test-unit.sh;
    "nix-misskey-test-e2e" = ./bin/test-e2e.sh;
    "nix-misskey-test-all" = ./bin/test-all.sh;
  };

  individualCommands = lib.mapAttrsToList mkCmd binSpecs;

  dispatcher = pkgs.writeShellApplication {
    name = "nix-misskey";
    runtimeInputs = individualCommands;
    text = ''
      show_help() {
        cat <<EOF
      Misskey Development Environment

      Usage: nix-misskey <namespace> <command> [args]
             nix-misskey <command>

      Top-level commands:
        status                       Show service status
        stop                         Stop PostgreSQL and Redis
        reset                        Destructive: clean + app setup
        clean                        Remove data, node_modules and config
        help                         Show this help

      Namespaced commands:
        app   setup | dev | build | migrate
        db    init  | start | stop | psql
        cache init  | start | stop | cli
        test  unit  | e2e   | all

      Logs:
        logs  db | cache | app | all
      EOF
      }

      ns="''${1:-help}"

      case "$ns" in
        app|db|cache|test)
          shift
          sub="''${1:-}"
          if [ -z "$sub" ]; then
            show_help
            exit 1
          fi
          shift
          exec "nix-misskey-$ns-$sub" "$@"
          ;;
        logs|status|stop|reset|clean)
          shift
          exec "nix-misskey-$ns" "$@"
          ;;
        help|-h|--help|"")
          show_help
          ;;
        *)
          show_help
          exit 1
          ;;
      esac
    '';
  };

  misskeyEnv = pkgs.symlinkJoin {
    name = "nix-misskey";
    paths = [ dispatcher ] ++ individualCommands;
  };
in
{
  inherit misskeyEnv;
}
