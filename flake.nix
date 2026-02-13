{
  description = "Target-based NixOS kit (compute, computeplusstorage, storage): disko + impermanence + incus + optional iscsi/nfs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    bcrail.url = "github:cobdfamily/bcrail";
    bowenos-tools.url = "github:cobdfamily/bowenos-tools";
  };

  outputs = inputs@{ self, nixpkgs, disko, impermanence, installer, ... }:
    let
      defaultSystem = "x86_64-linux";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = (forAllSystems (system: {
      })) // {
      };

      nixosConfigurations = {
        compute = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/compute/disks.nix
            ./targets/compute/default.nix
          ];
        };

        computeplusstorage = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/computeplusstorage/disks.nix
            ./targets/computeplusstorage/default.nix
          ];
        };

        storage = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/storage/disks.nix
            ./targets/storage/default.nix
          ];
        };
      };
    };
}
