{ pkgs }:

let
  port = 6379;

  conf = pkgs.writeText "redis.conf" ''
    bind 127.0.0.1
    port ${toString port}
    daemonize yes
    save ""
    appendonly no
    stop-writes-on-bgsave-error no
    maxmemory 512mb
    maxmemory-policy noeviction
    databases 16
    tcp-keepalive 300
    supervised no
    loglevel notice
    always-show-logo no
  '';
in
{
  inherit port;

  packages = [ pkgs.redis ];

  vars = {
    REDIS_CONF = conf;
    REDIS_PORT = toString port;
  };

  lib = ./lib.sh;

  service = {
    name = "Redis";
    port = "$REDIS_PORT";
    running = "redis_running";
    ensure = "redis_ensure";
    stop = "redis_stop";
  };

  help = "Cache (cache:*)";
  commands = [
    {
      name = "cache:init";
      description = "Destructively re-initialize Redis";
      text = "redis_init";
    }
    {
      name = "cache:start";
      description = "Start Redis (idempotent)";
      text = ''
        redis_ensure
        success "Redis: running on $REDIS_PORT"
      '';
    }
    {
      name = "cache:stop";
      description = "Stop Redis";
      text = ''
        redis_stop
        success "Redis stopped"
      '';
    }
    {
      name = "cache:cli";
      description = "Open redis-cli session";
      text = ''exec redis-cli -p "$REDIS_PORT" "$@"'';
    }
  ];
}
