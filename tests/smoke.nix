# Exercises the built CLI against real PostgreSQL / Redis inside the sandbox.
# pnpm is stubbed: it records its arguments and fakes the side effects the CLI
# looks at (node_modules, the migrations table).
{ pkgs, mkCli }:

let
  cli = mkCli (
    pkgs.writeShellScriptBin "pnpm" ''
      echo "''${NODE_ENV-unset} $*" >> "$TMPDIR/pnpm.log"
      case "$1" in
        install) mkdir -p node_modules ;;
        migrate) psql -Xqc 'create table if not exists migrations (id int); insert into migrations values (1)' ;;
      esac
    ''
  );
in
pkgs.runCommand "nix-misskey-smoke"
  {
    nativeBuildInputs = [
      cli
      pkgs.git
    ];
    __darwinAllowLocalNetworking = true;
  }
  ''
    export HOME="$TMPDIR"
    cd "$TMPDIR"

    # Every sub-command is listed in the help.
    nix-misskey help > help.txt
    for bin in ${cli}/bin/nix-misskey-*; do
      name="''${bin##*/nix-misskey-}"
      grep -qE "^  (''${name}|''${name/-/:}) " help.txt \
        || { echo "missing from help: $name" >&2; exit 1; }
    done
    if nix-misskey no-such-command >/dev/null 2>&1; then exit 1; fi

    # Without a sandbox these would be the host's services: leave them alone.
    status="$(nix-misskey status)"
    if grep -q ': running on' <<< "$status"; then
      echo "PostgreSQL / Redis ports are already in use" >&2
      exit 1
    fi

    nix-misskey db:start
    nix-misskey cache:start
    [ "$(nix-misskey status | grep -c ': running on')" = 2 ]
    [ "$(nix-misskey db:psql -XAtc 'select current_database()')" = misskey ]
    [ "$(nix-misskey cache:cli ping)" = PONG ]

    # A restart keeps data.
    nix-misskey db:psql -Xqc 'create table t ()'
    nix-misskey db:stop
    nix-misskey db:start
    nix-misskey db:psql -Xqc 'drop table t'

    nix-misskey stop
    [ "$(nix-misskey status | grep -c 'not running')" = 2 ]

    nix-misskey cache:start
    nix-misskey clean
    [ ! -e data ]
    [ "$(nix-misskey status | grep -c 'not running')" = 2 ]

    # dev sets everything up on first run, and only then.
    echo '{ "name": "misskey" }' > package.json
    git init -q
    setup_then_dev='unset install --frozen-lockfile,unset build-pre,unset --filter backend... build,unset migrate,development dev,'
    pnpm_log() { tr '\n' , < pnpm.log; rm pnpm.log; }
    nix-misskey dev
    [ "$(pnpm_log)" = "$setup_then_dev" ]
    [ -f .config/default.yml ]

    nix-misskey dev
    [ "$(pnpm_log)" = 'development dev,' ]

    # Missing dependencies are installed again.
    rm -rf node_modules
    nix-misskey dev
    [ "$(pnpm_log)" = "$setup_then_dev" ]

    # A migration that never completed is retried.
    nix-misskey db:psql -Xqc 'truncate migrations'
    nix-misskey dev
    [ "$(pnpm_log)" = "$setup_then_dev" ]

    # A wiped database is migrated again.
    nix-misskey clean
    nix-misskey dev
    [ "$(pnpm_log)" = "$setup_then_dev" ]

    # An unreachable database is an error, not a reason to set up.
    if PGDATABASE=nope nix-misskey dev; then exit 1; fi
    [ ! -e pnpm.log ]

    # A hand-edited config may point at another database: never migrate it
    # unasked.
    nix-misskey db:psql -Xqc 'truncate migrations'
    echo '# edited' >> .config/default.yml
    nix-misskey dev
    [ "$(pnpm_log)" = 'development dev,' ]
    rm -rf node_modules
    if nix-misskey dev; then exit 1; fi
    [ ! -e pnpm.log ]

    nix-misskey stop
    touch "$out"
  ''
