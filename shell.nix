{ pkgs, scripts }:

pkgs.mkShell {
  name = "misskey-dev-shell";

  packages = with pkgs; [
    nodejs_22
    pnpm
    postgresql_15
    redis
    ffmpeg
    python311
    gcc
    git
    gnumake
    scripts.misskeyEnv
  ];

  shellHook = ''
    echo "🚀 Welcome to Misskey development environment"
    echo
    echo "Type 'nix-misskey help' to see available commands"
    echo
    if [ ! -f .config/default.yml ]; then
      echo "🔧 First time? Run 'nix-misskey setup' to initialize the environment"
    fi

    if [ -z "$DIRENV_IN_ENVRC" ]; then
      trap 'nix-misskey stop' EXIT
    fi

    export NODE_ENV="development"
    export VITE_PORT="5173"
    export EMBED_VITE_PORT="5174"
    export PORT="3000"

    export NODE_OPTIONS="--max-old-space-size=4096"
  '';

  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  LANG = "en_US.UTF-8";

  PGDATA = "$(pwd)/data/postgres";
  PGHOST = "localhost";
  PGUSER = "postgres";
  PGPASSWORD = "postgres";
  PGDATABASE = "misskey";
  PGPORT = "5433";
}
