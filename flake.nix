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
        ''
          if [ -f /etc/forgejo/app.ini ]; then
            exec ${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config /etc/forgejo/app.ini
          else
            ${pkgs.forgejo-runner}/bin/forgejo-runner generate-config > /tmp/app.ini
            ${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config /tmp/app.ini || exec ${pkgs.coreutils}/bin/sleep infinity
          fi
        ''
      ];
    };
  in {
    packages.${system} = {
      forgejo-runner-image = n2c.buildImage {
        name = "forgejo-runner";
        tag = "latest";
        fromImage = base.packages.${system}.base-debug-image;
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

      default = self.packages.${system}.forgejo-runner-image;
    };

    version = pkg.version;
  };
}
