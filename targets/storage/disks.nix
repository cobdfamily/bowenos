args: (import ../../modules/disko-zfs.nix (args // {
  config = { bowenos.storage.diskMode = "mirror"; };
}))
