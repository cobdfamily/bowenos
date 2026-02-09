# Hosts Inventory

Each host lives in its own directory:

```
hosts/<hostname>/
  local.nix
  hardware-configuration.nix
```

`local.nix` must export:

```nix
{
  target = "computeplusstorage"; # or compute/storage
  system = "x86_64-linux";       # optional
  module = { ... }: {
    bowenos.identity.hostName = "<hostname>";
    bowenos.identity.hostId = "deadbeef";
    bowenos.identity.target = "<target>";
  };
}
```

`local.nix` is the host-specific config (tracked), and
`hardware-configuration.nix` is the standard output of `nixos-generate-config`.
