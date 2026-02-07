{
  description = "Role-based NixOS kit (compute, computeplusstorage): disko + impermanence + incus + optional iscsi/nfs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, impermanence, ... }:
    let system = "x86_64-linux";
    in {
      nixosConfigurations = {
        compute = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./roles/compute/disks.nix
            ./roles/compute/default.nix
          ];
        };

        computeplusstorage = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./roles/computeplusstorage/disks.nix
            ./roles/computeplusstorage/default.nix
          ];
        };
      };
    };
}
