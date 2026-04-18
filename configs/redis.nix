{ pkgs }:

builtins.toFile "redis.conf" ''
  bind 127.0.0.1
  port 6379
  daemonize yes
  dir ./data/redis
  pidfile ./data/redis/redis.pid
  save ""
  appendonly no
  stop-writes-on-bgsave-error no
  maxmemory 512mb
  maxmemory-policy allkeys-lru
  databases 16
  tcp-keepalive 300
  supervised no
  loglevel notice
  logfile ./data/redis/redis.log
  always-show-logo no
''
