# Commands spanning every service, generated from the modules' `service` hooks.
{ pkgs, modules }:

let
  lib = pkgs.lib;
  services = map (m: m.service) modules;
  hooks =
    name: lib.concatMapStrings (s: lib.optionalString (s ? ${name}) "  ${s.${name}}\n") services;
in
{
  lib = pkgs.writeText "services.sh" ''
    # shellcheck shell=bash
    services_ensure() {
    ${hooks "ensure"}}

    services_stop() {
    ${hooks "stop"}}

    services_status() {
    ${
      lib.concatMapStrings (
        s:
        lib.optionalString (s ? running) ''
          if ${s.running}; then success "${s.name}: running on ${s.port}"; else warn "${s.name}: not running"; fi
        ''
      ) services
    }}
  '';

  help = "Services";
  commands = [
    {
      name = "status";
      description = "Show PostgreSQL / Redis status";
      text = "services_status";
    }
    {
      name = "stop";
      description = "Stop all services";
      text = ''
        log "Stopping services..."
        services_stop
        success "Services stopped"
      '';
    }
    {
      name = "logs";
      usage = "logs <db|cache|app|all>";
      description = "Tail logs";
      text = ''
        svc="''${1:-all}"
        case "$svc" in
          db|postgres) tail -F "$PGDATA"/log/*.log ;;
          cache|redis) tail -F "$REDIS_DIR"/redis.log ;;
          app|misskey) tail -F "$LOG_DIR"/* 2>/dev/null || warn "no app logs yet" ;;
          all)
            shopt -s nullglob
            files=("$PGDATA"/log/*.log "$REDIS_DIR"/redis.log "$LOG_DIR"/*)
            shopt -u nullglob
            [ "''${#files[@]}" -gt 0 ] || error "no logs to tail"
            tail -F "''${files[@]}"
            ;;
          *) error "unknown log target: $svc (db|cache|app|all)" ;;
        esac
      '';
    }
  ];
}
