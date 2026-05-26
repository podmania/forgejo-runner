{
  description = "Forgejo-runner distroless image using nix2container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container.url = "github:nlewo/nix2container";
    base.url = "github:podmania/base";
  };

  outputs = { self, nixpkgs, nix2container, base }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
    n2c = nix2container.outputs.packages.${system}.nix2container;
    version = "12.10.2";
    srcHash = "sha256-2PQPs7aIHd2h6bBiyQtFh+5afaI2uAq5mhx//xtifWE=";
    pkg = pkgs.forgejo-runner.overrideAttrs (old: {
      inherit version;
      src = pkgs.fetchurl {
        url = "https://code.forgejo.org/forgejo/runner/archive/v${version}.tar.gz";
        hash = srcHash;
      };
      ldflags = [
        "-s"
        "-w"
        "-X code.forgejo.org/forgejo/runner/v${builtins.elemAt (builtins.splitVersion version) 0}/internal/pkg/ver.version=v${version}"
      ];
    });
    imageConfig = {
      ExposedPorts = {
        
      };
      Volumes = {
        
      };
      
      Cmd = [ "${pkg}/bin/forgejo-runner" ];
    };
  in {
    packages.${system} = {
      forgejo-runner-image = n2c.buildImage {
        name = "forgejo-runner";
        tag = "latest";
        fromImage = base.packages.${system}.base-image;
        maxLayers = 5;
        config = imageConfig;
      };

      forgejo-runner-debug-image = n2c.buildImage {
        name = "forgejo-runner";
        tag = "latest-debug";
        fromImage = base.packages.${system}.base-debug-image;
        maxLayers = 5;
        config = imageConfig;
      };

      forgejo-runner = pkg;

      default = self.packages.${system}.forgejo-runner-image;
    };

    forgejo-runnerVersion = version;
  };
}
