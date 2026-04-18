require_misskey_repo
export NODE_ENV=production
log "Resetting environment..."
do_clean_all
do_setup
success "Reset completed"
