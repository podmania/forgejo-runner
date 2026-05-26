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
    imageConfig = {
      Volumes = {
        "/data" = {};
      };
      Env = [
        "HOME=/data"
      ];
      WorkingDir = "/data";
      Cmd = [ "${pkgs.forgejo-runner}/bin/forgejo-runner" "daemon" "--config" "/data/config.yaml" ];
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
