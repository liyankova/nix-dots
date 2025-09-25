# ~/dotfiles/nix/home/liyan/default.nix
{ pkgs, ... }:

{
  # This is the main entry point for the user configuration.

  home.username = "liyan";
  home.homeDirectory = "/home/users";

  # This value should not be changed after the first use.
  home.stateVersion = "25.05";

  home.enableNixpkgsReleaseCheck = false;
  # An empty list for now, we will add packages here later.
  home.packages = with pkgs; [ 
        # --- CLI Utilities ---
    btop
    fastfetch
    tree
    tmux
    wget
    gh    # GitHub CLI
    stow  # Symlink farm manager

    # --- Development ---
    kitty
    vim
    neovim
    oh-my-posh

    # --- Desktop & Wayland ---
    firefox
    obsidian # Electron app, kept in Nix as requested
    
    # Wayland core utilities (from unstable for latest fixes)
    pkgs-unstable.wl-clipboard
    pkgs-unstable.cliphist
    pkgs-unstable.grim
    pkgs-unstable.slurp
    pkgs-unstable.swappy   # Screenshot editor
    pkgs-unstable.swww     # Wallpaper daemon
    pkgs-unstable.wlogout  # Logout menu
    pkgs-unstable.swaynotificationcenter
    
    # App Launchers (sticking to rofi as per old config)
    rofi 

    # Audio & System Control
    pamixer      # PulseAudio/PipeWire mixer
    pavucontrol
    brightnessctl
    nwg-look     # GTK theme switcher
  ];

  # Allow Home Manager to manage itself
  programs.home-manager.enable = true;

  # Home Manager modules for programs.
  programs = {
    # The Waybar panel
    waybar.enable = true;

    # Allow Home Manager to manage itself
    home-manager.enable = true;
  };

}
