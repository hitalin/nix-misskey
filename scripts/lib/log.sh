# shellcheck shell=bash
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log()     { printf '%s[Misskey]%s %s\n' "$BLUE"   "$NC" "$1"; }
success() { printf '%s✓%s %s\n'         "$GREEN"  "$NC" "$1"; }
warn()    { printf '%s!%s %s\n'         "$YELLOW" "$NC" "$1"; }
error()   { printf '%s✗%s %s\n'         "$RED"    "$NC" "$1" >&2; return 1; }
