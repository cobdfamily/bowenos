{
  description = "Role-based NixOS kit (compute, computeplusstorage): disko + impermanence + incus + optional iscsi/nfs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    installer.url = "path:./installer/flakes/iso?narHash=sha256-9B6mK5802wfkZR5n8xrOKS/8/VjgH4jly0E+FuqfCU8=";
  };

  outputs = { self, nixpkgs, disko, impermanence, installer, ... }:
    let
      defaultSystem = "x86_64-linux";
    in {
      packages.${defaultSystem}.iso = installer.packages.${defaultSystem}.iso;
      nixosConfigurations = {
        compute = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/compute/disks.nix
            ./targets/compute/default.nix
          ];
        };

        computeplusstorage = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/computeplusstorage/disks.nix
            ./targets/computeplusstorage/default.nix
          ];
        };

        storage = nixpkgs.lib.nixosSystem {
          system = defaultSystem;
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
