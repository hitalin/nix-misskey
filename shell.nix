{
  pkgs,
  scripts,
  nodejs,
  pnpmShim,
}:

pkgs.mkShell {
  name = "misskey-dev-shell";

  packages = [
    nodejs
    pnpmShim
    scripts.misskeyEnv
  ]
  ++ (with pkgs; [
    postgresql_15
    redis
    ffmpeg
    python311
    gcc
    git
    gnumake
  ]);

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

    export VITE_PORT="5173"
    export EMBED_VITE_PORT="5174"
    export PORT="3000"
    export NODE_OPTIONS="--max-old-space-size=4096"

    export PGDATA="$PWD/data/postgres"
    export PGHOST="localhost"
    export PGUSER="postgres"
    export PGPASSWORD="postgres"
    export PGDATABASE="misskey"
    export PGPORT="5433"

    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  '';

  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  LANG = "en_US.UTF-8";
}
