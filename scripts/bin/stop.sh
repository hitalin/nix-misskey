log "Stopping services..."
pg_stop
redis_stop
meili_test_stop
success "Services stopped"
