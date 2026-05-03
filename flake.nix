{
  description = "NixOS configuration — life7vision | Hyprland + Home-Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, noctalia, hyprland, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # ── Ana sistem config ──────────────────────────────
        ./configuration.nix

        # ── Hyprland NixOS modülü (0.54, hyprlang) ────────
        hyprland.nixosModules.default

        # ── Noctalia Shell ─────────────────────────────────
        {
          environment.systemPackages = [
            inputs.noctalia.packages.x86_64-linux.default
          ];
          nix.settings = {
            extra-substituters = [ "https://noctalia.cachix.org" ];
            extra-trusted-public-keys = [
              "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            ];
          };
        }

        # ── Home-Manager (NixOS modülü olarak) ─────────────
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs        = true;
          home-manager.useUserPackages      = true;
          home-manager.backupFileExtension  = "bak";
          home-manager.extraSpecialArgs     = { inherit inputs; };
          home-manager.users.life7vision    = import ./home.nix;
        }
      ];
    };
  };
}
