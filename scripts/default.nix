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
  # Naming follows Misskey upstream: flat top-level commands, colon-prefixed
  # for namespaced subcommands. Internal bin filenames use a hyphen because
  # ":" is awkward in shell completion / grep patterns; the dispatcher maps
  # "ns:sub" -> "nix-misskey-ns-sub".
  binSpecs = {
    "nix-misskey-dev" = ./bin/dev.sh;
    "nix-misskey-setup" = ./bin/setup.sh;
    "nix-misskey-build" = ./bin/build.sh;
    "nix-misskey-migrate" = ./bin/migrate.sh;
    "nix-misskey-revert" = ./bin/revert.sh;
    "nix-misskey-status" = ./bin/status.sh;
    "nix-misskey-stop" = ./bin/stop.sh;
    "nix-misskey-clean" = ./bin/clean.sh;
    "nix-misskey-clean-all" = ./bin/clean-all.sh;
    "nix-misskey-reset" = ./bin/reset.sh;
    "nix-misskey-logs" = ./bin/logs.sh;
    "nix-misskey-test" = ./bin/test.sh;
    "nix-misskey-test-unit" = ./bin/test-unit.sh;
    "nix-misskey-test-e2e" = ./bin/test-e2e.sh;
    "nix-misskey-db-init" = ./bin/db-init.sh;
    "nix-misskey-db-start" = ./bin/db-start.sh;
    "nix-misskey-db-stop" = ./bin/db-stop.sh;
    "nix-misskey-db-psql" = ./bin/db-psql.sh;
    "nix-misskey-cache-init" = ./bin/cache-init.sh;
    "nix-misskey-cache-start" = ./bin/cache-start.sh;
    "nix-misskey-cache-stop" = ./bin/cache-stop.sh;
    "nix-misskey-cache-cli" = ./bin/cache-cli.sh;
  };

  individualCommands = lib.mapAttrsToList mkCmd binSpecs;

  dispatcher = pkgs.writeShellApplication {
    name = "nix-misskey";
    runtimeInputs = individualCommands;
    text = ''
      show_help() {
        cat <<EOF
      Misskey Development Environment

      Usage: nix-misskey <command> [args]

      App / lifecycle:
        dev              Ensure services + run pnpm dev
        setup            Install deps, build, migrate (initial)
        build            pnpm build
        migrate          pnpm migrate
        revert           pnpm revert (rollback last DB migration)

      Services:
        status           Show PostgreSQL / Redis status
        stop             Stop PostgreSQL and Redis
        logs <db|cache|app|all>

      Cleanup:
        clean            Remove data and config (PG / Redis / .config)
        clean-all        clean + node_modules + built
        reset            clean-all + setup

      Database (db:*):
        db:init          Destructively re-initialize PostgreSQL
        db:start         Start PostgreSQL (idempotent)
        db:stop          Stop PostgreSQL
        db:psql          Open psql session

      Cache (cache:*):
        cache:init       Destructively re-initialize Redis
        cache:start      Start Redis (idempotent)
        cache:stop       Stop Redis
        cache:cli        Open redis-cli session

      Test:
        test             Run all tests
        test:unit        Backend unit tests
        test:e2e         Backend E2E tests

      help               Show this help
      EOF
      }

      cmd="''${1:-help}"
      shift || true

      case "$cmd" in
        help|-h|--help|"")
          show_help
          exit 0
          ;;
        *:*)
          target="nix-misskey-''${cmd%%:*}-''${cmd#*:}"
          ;;
        *)
          target="nix-misskey-$cmd"
          ;;
      esac

      if ! command -v "$target" >/dev/null 2>&1; then
        echo "Unknown command: $cmd" >&2
        show_help
        exit 1
      fi
      exec "$target" "$@"
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
