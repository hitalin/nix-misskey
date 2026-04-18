# shellcheck shell=bash
# Common helpers shared by all modules.

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log()     { printf '%s[Misskey]%s %s\n' "$BLUE"   "$NC" "$1"; }
success() { printf '%s✓%s %s\n'         "$GREEN"  "$NC" "$1"; }
warn()    { printf '%s!%s %s\n'         "$YELLOW" "$NC" "$1"; }
error()   { printf '%s✗%s %s\n'         "$RED"    "$NC" "$1" >&2; return 1; }

require_misskey_repo() {
  if [ ! -f package.json ] || ! grep -q '"name": "misskey"' package.json 2>/dev/null; then
    error "Run this command from the root of the misskey repository"
  fi
}

show_help() {
  cat <<EOF
Misskey Development Environment

Usage: nix-misskey <command> [args]

Commands:
  start       Ensure services + run dev server (auto-init if needed)
  setup       Install deps + build + migrate (run once after clone)
  stop        Stop PostgreSQL and Redis
  restart     stop && start
  status      Show service status
  reset       Destructively re-init data, deps, build (clean + setup)
  clean       Remove data, node_modules and config
  psql        Connect to misskey database
  redis-cli   Open redis-cli session
  logs [svc]  Tail logs (postgres|redis|misskey|all)
  test        Run all tests
  test:unit   Run backend unit tests
  test:e2e    Run backend e2e tests
  help        Show this help
EOF
}
