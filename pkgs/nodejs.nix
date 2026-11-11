{
  pkgs,
  lib,
  system,
}:

let
  pin = lib.importJSON ./nodejs.json;
  inherit (pin) version;

  arch =
    {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-x64";
      "aarch64-darwin" = "darwin-arm64";
    }
    .${system} or (throw "nodejs ${version}: unsupported system ${system}");

  sha256 = pin.sha256.${system};
in
pkgs.stdenv.mkDerivation {
  pname = "nodejs";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}-${arch}.tar.xz";
    inherit sha256;
  };

  nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
    pkgs.autoPatchelfHook
  ];

  buildInputs = lib.optionals pkgs.stdenv.isLinux [
    pkgs.stdenv.cc.cc.lib
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r ./* $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Node.js ${version} (vendored binary, pinned in pkgs/nodejs.json)";
    homepage = "https://nodejs.org";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "node";
  };
}
