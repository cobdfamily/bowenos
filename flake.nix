{
  description = "Role-based NixOS kit (compute, computeplusstorage): disko + impermanence + incus + optional iscsi/nfs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    installer.url = "path:./installer?narHash=sha256-9B6mK5802wfkZR5n8xrOKS/8/VjgH4jly0E+FuqfCU8=";
  };

  outputs = { self, nixpkgs, disko, impermanence, installer, ... }:
    let
      defaultSystem = "x86_64-linux";

      hostDirs =
        let
          entries = builtins.readDir ./hosts;
        in
        builtins.filter (n: entries.${n} == "directory") (builtins.attrNames entries);

      hostInfo =
        builtins.listToAttrs (map
          (name:
            let
              hostPath = ./hosts + "/${name}";
              hostFile = hostPath + "/host.nix";
              localFile = hostPath + "/local.nix";
              host = if builtins.pathExists hostFile then import hostFile else import localFile;
            in {
              name = name;
              value = { target = host.target; system = host.system or defaultSystem; };
            })
          hostDirs);

      mkHost =
        name:
        let
          hostPath = ./hosts + "/${name}";
          hostFile = hostPath + "/host.nix";
          localFile = hostPath + "/local.nix";
          host = if builtins.pathExists hostFile then import hostFile else import localFile;
          system = host.system or defaultSystem;
          target = host.target;
          hostModule = host.module or (throw "hosts/${name}/local.nix must export { target, module }");
          hw = hostPath + "/hardware-configuration.nix";
          local = hostPath + "/local.nix";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./targets/${target}/disks.nix
            ./targets/${target}/default.nix
            hostModule
          ]
          ++ (if builtins.pathExists hw then [ hw ] else [ ])
          ++ (if builtins.pathExists local then [ local ] else [ ]);
        };
    in {
      packages.${defaultSystem}.iso = installer.packages.${defaultSystem}.iso;

      hostInfo = hostInfo;

      nixosConfigurations =
        builtins.listToAttrs (map (name: { name = name; value = mkHost name; }) hostDirs)
        // {
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
