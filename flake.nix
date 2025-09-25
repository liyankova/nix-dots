{
  description = "Konfigurasi NixOS Liyan - Langkah Migrasi 1.1 (dengan GRUB)";

  # =========================================================================
  # 1. INPUTS: Dependensi eksternal
  # =========================================================================
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    agenix.url = "github:ryantm/agenix";
  };

  # =========================================================================
  # 2. CACHING: Optimisasi bandwidth
  # =========================================================================
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org?priority=10"
      "https://nix-community.cachix.org?priority=20"
      "https://hyprland.cachix.org?priority=30"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    auto-optimise-store = true;
  };

  # =========================================================================
  # 3. OUTPUTS: Konfigurasi sistem kita
  # =========================================================================
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.laptop-hp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./hardware-configuration.nix
        ({ config, pkgs, ... }: {
          
          # =================================================================
          # PENGATURAN INTI SISTEM
          # =================================================================
          time.timeZone = "Asia/Jakarta";
          i18n.defaultLocale = "en_US.UTF-8";
          users.users.liyan = {
            isNormalUser = true;
            description = "Liyan";
            home = "/home/liyan";
            extraGroups = [ "wheel" "games" "video" "adbusers" "kvm" ];
            shell = pkgs.zsh;
          };
          environment.systemPackages = with pkgs; [ git curl vim home-manager ];
          programs.zsh.enable = true;
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
          };
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };
          powerManagement.enable = true;
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;

          # =================================================================
          # BOOTLOADER (Diperbarui menggunakan GRUB sesuai file lama Anda)
          # =================================================================
          boot.loader.efi.canTouchEfiVariables = true;
          boot.loader.grub = {
            enable = true;
            efiSupport = true;
            device = "nodev"; # Penting untuk sistem EFI
            useOSProber = false; # Lebih aman untuk tidak menggunakan os-prober
            # Mempertahankan entri dual-boot Debian Anda
            extraEntries = ''
              menuentry "Debian" {
                search --fs-uuid --set=root 6ED1-C749
                chainloader /EFI/debian/shimx64.efi
              }
            '';
          };
          
          # =================================================================
          # DRIVER NVIDIA
          # =================================================================
          boot.kernelPackages = pkgs.linuxPackages_lts;
          hardware.opengl.enable = true;
          hardware.opengl.driSupport32Bit = true;
          services.xserver.videoDrivers = [ "nvidia" ];
          hardware.nvidia = {
            modesetting.enable = true;
            package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
            nvidiaSettings = true;
            open = false;
            prime = {
              sync.enable = true;
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
          };

          system.stateVersion = "25.05";
        })
      ];
    };
  };
}
