# shellcheck shell=bash
# Redis primitives. Higher-level commands compose these.

redis_running() { redis-cli -p 6379 ping >/dev/null 2>&1; }

redis_start() {
  if redis_running; then return 0; fi
  mkdir -p "$REDIS_DIR"
  install -m 644 "$REDIS_CONF" "$REDIS_DIR/redis.conf"
  redis-server "$REDIS_DIR/redis.conf" \
    --dir "$REDIS_DIR" \
    --pidfile "$REDIS_DIR/redis.pid" \
    --logfile "$REDIS_DIR/redis.log"
  for _ in $(seq 1 10); do
    redis_running && return 0
    sleep 1
  done
  error "Redis failed to start"
}

redis_stop() {
  if redis_running; then
    redis-cli shutdown nosave 2>/dev/null || true
  fi
}

# Destructive: wipe data dir and start fresh.
redis_init() {
  log "Initializing Redis..."
  redis_stop
  rm -rf "$REDIS_DIR"
  redis_start
  success "Redis initialized"
}

# Idempotent.
redis_ensure() {
  if [ ! -d "$REDIS_DIR" ]; then
    redis_init
  else
    redis_start
  fi
}
