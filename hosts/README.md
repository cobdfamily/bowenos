# Hosts Inventory

Each host lives in its own directory:

```
hosts/<hostname>/
  host.nix
  local.nix
  hardware-configuration.nix
```

`host.nix` must export:

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

`local.nix` can include host-specific overrides (tracked), and
`hardware-configuration.nix` is the standard output of `nixos-generate-config`.
