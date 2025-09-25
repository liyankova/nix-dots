# ~/dotfiles/nix/home/users/cli.nix
{ pkgs, pkgs-unstable, ... }:

{
  # --- Program Configurations ---
  programs = {
    # Git Configuration
    git = {
      enable = true;
      # User info is now managed in the flake's specialArgs for consistency,
      # but you can override it here if needed.
      # userName = "your-username";
      # userEmail = "your-email";
    };

    # Zsh Configuration
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [ "git" "sudo" ];
      };

      shellAliases = {
        # General Tools
        bat = "bat --paging=never";
        st = "kitty --class special_term";
        # eza aliases
        ls = "eza --icons";
        l = "eza -l --icons";
        la = "eza -la --icons";
        lt = "eza --tree --level=2 --icons";
      };

      history = {
        size = 10000;
        path = ".zsh_history";
	share = true;
      };
      
      # We will manage dotfiles declaratively later.
      # initContent is kept minimal.
      initContent = ''
        # Custom Functions
        mkcd () {
          mkdir -p "$@" && cd "$_";
        }      
	# Oh My Posh Prompt Initialization
        eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/wallust.omp.json)"

      '';
    };

    # Declarative Tool Integrations
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
    };
    # 'yazi' and 'bat' are enabled by being in home.packages
  };

  # --- Add necessary packages for the aliases and tools ---
  home.packages = with pkgs; [
    eza
    bat
    fzf
    zoxide
    (pkgs-unstable.yazi.override { withImagePreview = true; }) # Example of enabling a feature
  ];

  # --- Declarative PATH and Environment Variables ---
  # Nix and Home Manager handle most of these automatically.
  # We only need to define variables for tools outside of the Nix store.
  home.sessionVariables = {
    # GOPATH is useful for Go development tools
    GOPATH = "$HOME/go";
  };
  home.sessionPath = [
    # Add go's binary path
    "$HOME/go/bin"
  ];
}
