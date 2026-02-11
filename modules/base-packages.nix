{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    jq
    rsync
    utils-linux
  ];
}
