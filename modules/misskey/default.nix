{
  pkgs,
  nodejs,
  pnpmShim,
  postgres,
  redis,
}:

let
  port = 3000;
  vitePort = 5173;
  embedVitePort = 5174;

  config = pkgs.writeText "default.yml" ''
    url: "http://localhost:${toString port}/"
    port: ${toString port}
    db:
      host: "localhost"
      port: ${toString postgres.port}
      db: "${postgres.database}"
      user: "${postgres.user}"
      pass: "${postgres.password}"
    redis:
      host: "127.0.0.1"
      port: ${toString redis.port}
    id: "aid"
    vite:
      port: ${toString vitePort}
      embedPort: ${toString embedVitePort}
  '';
in
{
  packages = [
    nodejs
    pnpmShim
  ]
  ++ [ pkgs.git ];

  shellPackages = with pkgs; [
    ffmpeg
    python311
    gcc
    gnumake
  ];

  env = {
    PORT = toString port;
    VITE_PORT = toString vitePort;
    EMBED_VITE_PORT = toString embedVitePort;
    NODE_OPTIONS = "--max-old-space-size=4096";
    COREPACK_ENABLE_DOWNLOAD_PROMPT = "0";
    # Cache V8 bytecode across runs: pnpm / rolldown / vite / vitest start faster.
    NODE_COMPILE_CACHE = "\${XDG_CACHE_HOME:-$HOME/.cache}/nix-misskey/node-compile-cache";
  };

  vars.MISSKEY_DEFAULT = config;

  lib = ./lib.sh;

  help = "App / lifecycle";
  commands = [
    {
      name = "dev";
      description = "Ensure services, set up if needed, run pnpm dev";
      text = ''
        require_misskey_repo
        do_dev
      '';
    }
    {
      name = "setup";
      description = "Install deps, build backend, migrate";
      text = ''
        require_misskey_repo
        do_setup
        success "Setup completed"
      '';
    }
    {
      name = "build";
      description = "pnpm build";
      text = ''
        require_misskey_repo
        export NODE_ENV=production
        log "Building Misskey..."
        pnpm build
      '';
    }
    {
      name = "migrate";
      description = "pnpm migrate";
      text = ''
        require_misskey_repo
        pg_ensure
        log "Running migrations..."
        pnpm migrate
      '';
    }
    {
      name = "revert";
      description = "pnpm revert (rollback last DB migration)";
      text = ''
        require_misskey_repo
        pg_ensure
        log "Reverting last migration..."
        pnpm revert
      '';
    }
  ];
}
