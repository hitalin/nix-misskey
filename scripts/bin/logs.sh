svc="${1:-all}"
case "$svc" in
  db|postgres) tail -F "$PGDATA"/log/*.log ;;
  cache|redis) tail -F "$REDIS_DIR"/redis.log ;;
  app|misskey) tail -F "$LOG_DIR"/* 2>/dev/null || warn "no app logs yet" ;;
  all)
    shopt -s nullglob
    files=("$PGDATA"/log/*.log "$REDIS_DIR"/redis.log "$LOG_DIR"/*)
    shopt -u nullglob
    [ "${#files[@]}" -gt 0 ] || error "no logs to tail"
    tail -F "${files[@]}"
    ;;
  *) error "unknown log target: $svc (db|cache|app|all)" ;;
esac
