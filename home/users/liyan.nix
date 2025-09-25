# ~/dotfiles/nix/home/liyan/default.nix
{ pkgs, ... }:

{
  # This is the main entry point for the user configuration.

  home.username = "liyan";
  home.homeDirectory = "/home/users";

  # This value should not be changed after the first use.
  home.stateVersion = "25.05";

  # An empty list for now, we will add packages here later.
  home.packages = [ ];

  # Allow Home Manager to manage itself
  programs.home-manager.enable = true;
}
