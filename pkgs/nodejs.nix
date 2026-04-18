{ pkgs, lib, system }:

let
  version = "22.21.1";

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
      "x86_64-linux" = "680d3f30b24a7ff24b98db5e96f294c0070f8f9078df658da1bce1b9c9873c88";
      "aarch64-linux" = "e660365729b434af422bcd2e8e14228637ecf24a1de2cd7c916ad48f2a0521e1";
      "x86_64-darwin" = "2f4fd943768fdd82308da88bb53f3a16259275c770bc4393e45b986844ea3017";
      "aarch64-darwin" = "39f53ffcf1604291e85974c8588bb290c14b358ac085e342920e703651d63c5e";
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
