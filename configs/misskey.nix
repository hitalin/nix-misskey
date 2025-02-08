{ pkgs }:

let
  writeConfig = name: text: pkgs.writeTextFile {
    inherit name text;
  };
in
{
  default = writeConfig "default.yml" ''
    url: "http://localhost:3000/"
    port: 3000
    db:
      host: "localhost"
      port: 5433
      db: "misskey"
      user: "postgres"
      pass: "postgres"
    redis:
      host: "localhost"
      port: 6379
    id: "aid"
    vite:
      port: 5173
      embedPort: 5174
  '';

  test = writeConfig "test.yml" ''
    url: "http://localhost:3000/"
    port: 3000
    db:
      host: "localhost"
      port: 5433
      db: "misskey-test"
      user: "postgres"
      pass: "postgres"
    redis:
      host: "localhost"
      port: 6379
    id: "test"
  '';
}