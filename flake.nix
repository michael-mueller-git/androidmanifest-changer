{
  description = "Nix flake for the Android manifest Go tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        androidmanifest-changer = pkgs.buildGoModule {
          pname = "androidmanifest-changer";
          version = "1.0.2";
          src = ./.;
          vendorHash = "sha256-3NeXxub+XJxXN47s598dFGUT+ORu8+ZLxKybRtqGIjI=";
        };

        # Wrap with runtime deps (aapt2, zip)
        wrapped-androidmanifest-changer = pkgs.symlinkJoin {
          name = "androidmanifest-changer-wrapped";
          paths = [ androidmanifest-changer ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram "$out/bin/androidmanifest-changer" \
              --prefix PATH : "${pkgs.android-tools}/bin:${pkgs.zip}/bin:${pkgs.aapt}/bin"
          '';
        };
      in {
        packages.default = wrapped-androidmanifest-changer;
        packages.androidmanifest-changer = wrapped-androidmanifest-changer;

        apps.default = {
          type = "app";
          program = "${wrapped-androidmanifest-changer}/bin/androidmanifest-changer";
        };
        apps.androidmanifest-changer = {
          type = "app";
          program = "${wrapped-androidmanifest-changer}/bin/androidmanifest-changer";
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ wrapped-androidmanifest-changer ];
          buildInputs = with pkgs; [ go gopls delve gofumpt golangci-lint ];
        };
      });
}
