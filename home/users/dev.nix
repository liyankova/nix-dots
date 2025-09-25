# ~/dotfiles/nix/home/users/dev.nix
{ pkgs, pkgs-unstable, ... }:

{
  # A collection of development packages.
  home.packages = with pkgs; [
    # --- Go ---
    go
    gopls
    gotools
    delve

    # --- Rust ---
    cargo
    rustc
    rust-analyzer
    pkg-config # Often needed for building Rust crates
    openssl    # Common dependency for Rust networking crates

    # --- NodeJS ---
    # Using the latest stable version from nixpkgs-unstable
    pkgs-unstable.nodejs_22
    pkgs-unstable.nodePackages.pnpm
    pkgs-unstable.nodePackages.typescript
    pkgs-unstable.nodePackages.eslint
  ];
}
