{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    jq
    nfs-utils
    rsync
    tmux
    util-linux
    wget
    vim
  ];
}
