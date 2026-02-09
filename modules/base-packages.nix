{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    jq
  ];
}
