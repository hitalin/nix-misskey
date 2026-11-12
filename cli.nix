# Builds the `nix-misskey` CLI out of the modules.
{ pkgs, modules }:

let
  lib = pkgs.lib;
  inherit (modules) all;

  runtimeInputs =
    modules.packages
    ++ (with pkgs; [
      coreutils
      diffutils
      gnugrep
      gnused
      gawk
    ]);

  # Shared header injected at the top of every sub-command: environment
  # defaults, then each module's variables and library.
  header = lib.concatStrings (
    lib.mapAttrsToList (k: v: ''export ${k}="''${${k}:-${v}}"'' + "\n") modules.env
    ++ lib.concatMap (m: lib.mapAttrsToList (k: v: "${k}='${v}'\n") (m.vars or { })) all
    ++ map (m: "# shellcheck source=/dev/null\n. '${m.lib}'\n") (lib.filter (m: m ? lib) all)
  );

  # Naming follows Misskey upstream: flat top-level commands, colon-prefixed
  # for namespaced subcommands. Bin names use a hyphen because ":" is awkward
  # in shell completion / grep patterns; the dispatcher maps
  # "ns:sub" -> "nix-misskey-ns-sub".
  mkCmd =
    cmd:
    pkgs.writeShellApplication {
      name = "nix-misskey-" + lib.replaceStrings [ ":" ] [ "-" ] cmd.name;
      inherit runtimeInputs;
      text = header + cmd.text;
      excludeShellChecks = [
        "SC2034" # variables in header may be unused by a given sub-command
      ];
    };

  individualCommands = map mkCmd (lib.concatMap (m: m.commands or [ ]) all);

  pad = s: s + lib.concatStrings (lib.genList (_: " ") (lib.max 1 (17 - lib.stringLength s)));

  help = pkgs.writeText "nix-misskey-help" (
    ''
      Misskey Development Environment

      Usage: nix-misskey <command> [args]

    ''
    + lib.concatMapStrings (
      m:
      "${m.help}:\n"
      + lib.concatMapStrings (c: "  ${pad (c.usage or c.name)}${c.description}\n") m.commands
      + "\n"
    ) (lib.filter (m: m ? commands) all)
    + ''
      help               Show this help
    ''
  );

  dispatcher = pkgs.writeShellApplication {
    name = "nix-misskey";
    runtimeInputs = individualCommands;
    text = ''
      show_help() { cat '${help}'; }

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
in
pkgs.symlinkJoin {
  name = "nix-misskey";
  paths = [ dispatcher ] ++ individualCommands;
}
