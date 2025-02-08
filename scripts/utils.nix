{ pkgs }:

{
  functions = ''
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    log() { echo -e "''${BLUE}[Misskey]''${NC} $1"; }
    success() { echo -e "''${GREEN}✓''${NC} $1"; }
    error() { echo -e "''${RED}✗''${NC} $1"; return 1; }

    show_help() {
      echo "Misskey Development Environment"
      echo
      echo "Usage: nix-misskey <command>"
      echo
      echo "Commands:"
      echo "  setup   - Initial setup"
      echo "  start   - Start development server"
      echo "  stop    - Stop all services"
      echo "  clean   - Clean environment"
      echo "  reset   - Reset and setup again"
      echo "  psql    - Connect to database"
      echo "  status  - Check services status"
      echo "  logs    - View logs (postgres|all)"
      echo "  test    - Run tests"
      echo "  test:e2e - Run E2E tests"
      echo "  test:unit - Run unit tests"
      exit 1
    }
  '';
}
