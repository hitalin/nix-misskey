{ pkgs, lib, system }:

let
  version = "22.15.0";

  arch =
    {
      "x86_64-linux" = "linux-x64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-x64";
      "aarch64-darwin" = "darwin-arm64";
    }
    .${system} or (throw "nodejs ${version}: unsupported system ${system}");

  sha256 =
    {
      "x86_64-linux" = "dafe2e8f82cb97de1bd10db9e2ec4c07bbf53389b0799b1e095a918951e78fd4";
      "aarch64-linux" = "d68adf72c531f1118bee75b20ffbc5911accfda5e73454a798625464b40a4adf";
      "x86_64-darwin" = "7dab3f93551d88f1e63db6b32bae6d4858e16740e9849ebbeac1d43f5055d8f0";
      "aarch64-darwin" = "6e278a107d50da24b644dd26810a639a5f8ca67b55086e6b693caabcbb759912";
    }
    .${system};
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
    description = "Node.js ${version} (vendored binary, matches yamisskey .node-version)";
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
