{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = import nixpkgs { inherit system; }; in
        let
          wowdefs =
            pkgs.stdenv.mkDerivation {
              name = "vscode-wow-api";
              src = pkgs.fetchFromGitHub {
                owner = "Ketho";
                repo = "vscode-wow-api";
                rev = "2a9e7ef218d7a893156e15fd2a66799ff457c941";
                sha256 = "sha256-09QFnejehKXutWhu9QJM53T6Sf+FeX/bXgKQ6Pgthis=";
              };
              installPhase = ''
                mkdir -p $out;
                cp -r ./EmmyLua $out/EmmyLua;
              '';
            };
        in
        with pkgs; {
          formatter = nixpkgs-fmt;
          devShells.default = mkShell {
            packages = [ stylua lua51Packages.lua lua51Packages.luarocks ];
            buildInputs = [
              wowdefs
            ];
          };
        });
}
