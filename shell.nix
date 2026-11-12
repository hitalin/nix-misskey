{
  pkgs,
  cli,
  modules,
  nodejs,
}:

pkgs.mkShell (
  {
    name = "misskey-dev-shell";

    packages = [ cli ] ++ modules.packages ++ modules.shellPackages;

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
        printf ' First time? %snix-misskey dev%s sets everything up.\n' "$_B" "$_R"
      fi
      if [ -f .node-version ] && [ "$(cat .node-version)" != "${nodejs.version}" ]; then
        printf ' %s!%s .node-version wants Node %s but this shell pins ${nodejs.version}.\n' "$_G" "$_R" "$(cat .node-version)"
        if [ -x .nix-misskey/pkgs/update-nodejs.sh ]; then
          printf '   Run %s.nix-misskey/pkgs/update-nodejs.sh "$(cat .node-version)"%s to re-pin.\n' "$_B" "$_R"
        else
          printf '   Clone nix-misskey as %s.nix-misskey%s to re-pin (see README).\n' "$_B" "$_R"
        fi
      fi
      printf '\n'
      unset _G _D _B _R

      if [ -z "$DIRENV_IN_ENVRC" ]; then
        trap 'nix-misskey stop' EXIT
      fi

      ${
        pkgs.lib.concatStrings (
          pkgs.lib.mapAttrsToList (k: v: ''
            export ${k}="${v}"
          '') modules.env
        )
      }    '';

    LANG = "en_US.UTF-8";
  }
  # glibcLocales only exists on Linux.
  // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  }
)
