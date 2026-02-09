{
  description = "BowenOS host inventory flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    bowenos.url = "path:../../..";
  };

  outputs = { self, nixpkgs, disko, impermanence, bowenos, ... }:
    let
      inherit (nixpkgs) lib;
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
              localFile = hostPath + "/local.nix";
              host = import localFile;
            in {
              name = name;
              value = { target = host.target; system = host.system or defaultSystem; };
            })
          hostDirs);

      mkHost =
        name:
        let
          hostPath = ./hosts + "/${name}";
          localFile = hostPath + "/local.nix";
          host = import localFile;
          system = host.system or defaultSystem;
          target = host.target;
          hostModule = host.module or (throw "hosts/${name}/local.nix must export { target, module }");
          hw = hostPath + "/hardware-configuration.nix";
          local = hostPath + "/local.nix";
          identityDefaults = { ... }: {
            bowenos.identity.hostName = lib.mkDefault name;
            bowenos.identity.target = lib.mkDefault target;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            bowenos.outPath + "/targets/${target}/disks.nix"
            bowenos.outPath + "/targets/${target}/default.nix"
            identityDefaults
            hostModule
          ]
          ++ (if builtins.pathExists hw then [ hw ] else [ ])
          ++ (if builtins.pathExists local then [ local ] else [ ]);
        };
    in {
      hostInfo = hostInfo;
      nixosConfigurations =
        builtins.listToAttrs (map (name: { name = name; value = mkHost name; }) hostDirs);
    };
}
