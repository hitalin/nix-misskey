if pg_running;    then success "PostgreSQL: running on $PGPORT"; else warn "PostgreSQL: not running"; fi
if redis_running; then success "Redis: running on 6379";          else warn "Redis: not running"; fi
