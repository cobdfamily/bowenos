{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    jq
    nfs-utils
    rsync
    util-linux
    wget
    vim
  ];
}
