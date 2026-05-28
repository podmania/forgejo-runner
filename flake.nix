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
    n2c = nix2container.packages.${system}.nix2container;
    pkg = pkgs.forgejo-runner;

    imageConfig = {
      Volumes = {
        "/data" = {};
        "/etc/forgejo" = {};
      };
      Env = [
        "HOME=/data"
      ];
      WorkingDir = "/data";
      Cmd = [
        "${pkgs.bash}/bin/bash" "-c"
        "${pkgs.forgejo-runner}/bin/forgejo-runner generate-config > /etc/forgejo/app.ini && exec ${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config /etc/forgejo/app.ini"
      ];
    };
  in {
    packages.${system} = let
      image = n2c.buildImage {
        name = "forgejo-runner";
        tag = "latest";
        fromImage = base.packages.${system}.base-debug-image;
        maxLayers = 5;
        config = imageConfig;
      };
    in {
      forgejo-runner-image = image;
      copyToDockerDaemon = n2c.copyToDockerDaemon image;
      copyToRegistry = n2c.copyToRegistry image;
      default = self.packages.${system}.forgejo-runner-image;
    };

    version = pkg.version;
  };
}
