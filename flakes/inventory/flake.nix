{
  description = "BowenOS host inventory flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    bcrail.url = "github:cobdfamily/bcrail";
    bowenos.url = "github:cobdfamily/bowenos";
  };

  outputs = inputs@{ self, nixpkgs, disko, impermanence, bowenos, ... }:
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
              value = {
                target = host.target;
                system = host.system or defaultSystem;
                bootaById = host.bootaById or "";
                bootbById = host.bootbById or "";
                diskMode = host.diskMode or "mirror";
                bootMode = host.bootMode or "uefi";
              };
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
          hostModule = host.module or (_: { });
          hw = hostPath + "/hardware-configuration.nix";
          usersFile = hostPath + "/users.nix";
          identityDefaults = { ... }: {
            bowenos.identity.hostName = lib.mkDefault name;
            bowenos.identity.target = lib.mkDefault target;
          };
          shortModule = { lib, ... }: {
            bowenos.identity.hostId = lib.mkDefault (host.hostId or "");
            bowenos.identity.hostName = lib.mkDefault (host.hostName or name);
            bowenos.identity.timeZone = lib.mkDefault (host.timeZone or "America/Vancouver");
            bowenos.identity.locale = lib.mkDefault (host.locale or "en_CA.UTF-8");
            bowenos.identity.target = lib.mkDefault (target);

            bowenos.users.adminUser = lib.mkDefault (host.adminUser or "admin");
            bowenos.users.sshPubKey = lib.mkDefault (host.sshPubKey or "");
            bowenos.users.allowNoKey = lib.mkDefault (host.allowNoKey or false);
            bowenos.users.sudoNeedsPassword = lib.mkDefault (host.sudoNeedsPassword or false);
            bowenos.users.mutableUsers = lib.mkDefault (host.mutableUsers or false);
            bowenos.users.consolePassword = lib.mkDefault (host.consolePassword or "");

            bowenos.storage.isVm = lib.mkDefault (host.isVm or false);
            bowenos.storage.diskMode = lib.mkDefault (host.diskMode or "mirror");
            bowenos.storage.bootaById = lib.mkForce (host.bootaById or "");
            bowenos.storage.bootbById = lib.mkForce (host.bootbById or "");
            bowenos.storage.bootMode = lib.mkDefault (host.bootMode or "uefi");
            bowenos.storage.bootbDiskPath = lib.mkDefault (host.bootbDiskPath or "");
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules =
            [
              disko.nixosModules.disko
              impermanence.nixosModules.impermanence
            ]
            ++ (if builtins.pathExists hw then [ hw ] else [ ])
            ++ (if builtins.pathExists usersFile then [ usersFile ] else [ ])
            ++ [
              identityDefaults
              shortModule
              hostModule
              "${bowenos.outPath}/targets/${target}/disks.nix"
              "${bowenos.outPath}/targets/${target}/default.nix"
            ];
        };
    in {
      hostInfo = hostInfo;
      hosts =
        builtins.listToAttrs (map
          (name:
            let
              hostPath = ./hosts + "/${name}";
              localFile = hostPath + "/local.nix";
              host = import localFile;
            in {
              name = name;
              value = {
                bootaById = host.bootaById or "";
                bootbById = host.bootbById or "";
              };
            })
          hostDirs);
      nixosConfigurations =
        builtins.listToAttrs (map (name: { name = name; value = mkHost name; }) hostDirs);
    };
}
