{
  pkgs,
  postgres,
  redis,
}:

let
  database = "misskey-test";

  # Mirrors upstream .github/misskey/test.yml, pointed at the nix-misskey services.
  config = pkgs.writeText "test.yml" ''
    url: "http://misskey.local"
    setupPassword: "example_password_please_change_this_or_you_will_get_hacked"
    port: 61812
    db:
      host: "localhost"
      port: ${toString postgres.port}
      db: "${database}"
      user: "${postgres.user}"
      pass: "${postgres.password}"
    redis:
      host: "127.0.0.1"
      port: ${toString redis.port}
      db: 1
    id: "aidx"
    proxyRemoteFiles: true
  '';
in
{
  vars = {
    MISSKEY_TEST = config;
    MISSKEY_TEST_DB = database;
  };

  lib = ./lib.sh;

  help = "Test";
  commands = [
    {
      name = "test";
      description = "Run all tests";
      text = ''
        require_misskey_repo
        log "Running all tests..."
        run_test_all
      '';
    }
    {
      name = "test:unit";
      description = "Backend unit tests";
      text = ''
        require_misskey_repo
        log "Running backend unit tests..."
        run_test_unit "$@"
      '';
    }
    {
      name = "test:e2e";
      description = "Backend E2E tests";
      text = ''
        require_misskey_repo
        log "Running backend e2e tests..."
        run_test_e2e "$@"
      '';
    }
  ];
}
