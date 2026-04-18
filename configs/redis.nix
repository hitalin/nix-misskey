{ pkgs }:

builtins.toFile "redis.conf" ''
  bind 127.0.0.1
  port 6379
  daemonize yes
  save ""
  appendonly no
  stop-writes-on-bgsave-error no
  maxmemory 512mb
  maxmemory-policy allkeys-lru
  databases 16
  tcp-keepalive 300
  supervised no
  loglevel notice
  always-show-logo no
''
