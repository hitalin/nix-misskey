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
    if [ -z "$NO_COLOR" ]; then
      _G=$'\033[38;2;134;179;0m'   # Misskey theme color #86b300
      _D=$'\033[90m'
      _B=$'\033[1m'
      _R=$'\033[0m'
    else
      _G=""; _D=""; _B=""; _R=""
    fi

    printf '\n'
    printf '%s  _____ _         _           %s\n'  "$_G" "$_R"
    printf '%s |     |_|___ ___| |_ ___ _ _ %s\n'  "$_G" "$_R"
    printf "%s | | | | |_ -|_ -| '_| -_| | |%s\n"  "$_G" "$_R"
    printf '%s |_|_|_|_|___|___|_,_|___|_  |%s\n'  "$_G" "$_R"
    printf '%s                         |___|%s %snix-dev%s\n' "$_G" "$_R" "$_D" "$_R"
    printf '\n'
    printf ' %sAn interplanetary microblogging platform.%s\n' "$_D" "$_R"
    printf ' Run %snix-misskey help%s to see available commands.\n' "$_B" "$_R"
    if [ ! -f .config/default.yml ]; then
      printf ' First time? Run %snix-misskey setup%s to initialize.\n' "$_B" "$_R"
    fi
    printf '\n'
    unset _G _D _B _R

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
