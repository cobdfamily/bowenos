{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    jq
    rsync
    util-linux
    wget
    vim
  ];
}
