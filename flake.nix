{
  description = "Liyan's NixOS Configuration";

  # --- Flake Inputs ---
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

  # --- System-wide Cachix Configuration ---
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

  # --- Flake Outputs ---
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.laptop-hp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./hardware-configuration.nix
        ({ config, pkgs, lib, ... }: {
          
          nixpkgs.config.allowUnfree = true;

	  nixpkgs.config.nvidia.acceptLicense = true;

          # --- Core System Configuration ---
          time.timeZone = "Asia/Jakarta";
          i18n.defaultLocale = "en_US.UTF-8";
          users.users.liyan = {
            isNormalUser = true;
            description = "Liyan";
            home = "/home/liyan";
            extraGroups = [ "wheel" "games" "video" "adbusers" "kvm" "networkmanager" ]; 
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
          
          # --- EFI Bootloader using GRUB ---
          boot.loader.efi.canTouchEfiVariables = true;
          boot.loader.grub = {
            enable = true;
            efiSupport = true;
            device = "nodev";
            useOSProber = false;
            extraEntries = ''
              menuentry "Debian" {
                search --fs-uuid --set=root 6ED1-C749
                chainloader /EFI/debian/shimx64.efi
              }
            '';
          };
          
          # --- NVIDIA Legacy Driver & Graphics ---
          boot.kernelPackages = pkgs.linuxPackages;
          hardware.graphics = {
            enable = true;
            enable32Bit = true;
          };
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

          # --- System Services ---
          # (Imported from old config)
          
          # Networking
          networking.hostName = "nixos";
          networking.networkmanager.enable = true;

          # Audio with PipeWire
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            wireplumber.enable = true;
          };
          # Ensure legacy audio servers are disabled
          services.pulseaudio.enable = false;
          sound.enable = false;

          # Display Manager (Login Screen)
          services.libinput.enable = true;
          services.displayManager = {
            sddm.enable = true;
            defaultSession = "hyprland";
          };

          # BTRFS Snapshots with Snapper
          services.btrfs.autoScrub.enable = true;
          services.snapper = {
            configs."root" = {
              SUBVOLUME = "/";
              ALLOW_USERS = [ "liyan" ];
              TIMELINE_CREATE = true;
            };
          };
          
          # Flatpak Support
          services.flatpak.enable = true;

          system.stateVersion = "25.05";
        })
      ];
    };
  };
}

# {
#   description = "Konfigurasi NixOS Liyan - Langkah Migrasi 1.1 (dengan GRUB)";
#
#   # =========================================================================
#   # 1. INPUTS: Dependensi eksternal
#   # =========================================================================
#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
#     nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
#     home-manager = {
#       url = "github:nix-community/home-manager/release-25.05";
#       inputs.nixpkgs.follows = "nixpkgs";
#     };
#     hyprland.url = "github:hyprwm/Hyprland";
#     agenix.url = "github:ryantm/agenix";
#   };
#
#   # =========================================================================
#   # 2. CACHING: Optimisasi bandwidth
#   # =========================================================================
#   nixConfig = {
#     extra-substituters = [
#       "https://cache.nixos.org?priority=10"
#       "https://nix-community.cachix.org?priority=20"
#       "https://hyprland.cachix.org?priority=30"
#     ];
#     extra-trusted-public-keys = [
#       "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
#       "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
#       "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
#     ];
#     auto-optimise-store = true;
#   };
#
#   # =========================================================================
#   # 3. OUTPUTS: Konfigurasi sistem kita
#   # =========================================================================
#   outputs = { self, nixpkgs, ... }@inputs: {
#     nixosConfigurations.laptop-hp = nixpkgs.lib.nixosSystem {
#       system = "x86_64-linux";
#       specialArgs = { inherit inputs; };
#
#       modules = [
#         ./hardware-configuration.nix
#         ({ config, pkgs, ... }: {
#
#           # =================================================================
#           # PENGATURAN INTI SISTEM
#           # ================================================================= 
# 	  nixpkgs.config.allowUnfree = true;
# 	  nixpkgs.config.nvidia.acceptLicense = true;
#           time.timeZone = "Asia/Jakarta";
#           i18n.defaultLocale = "en_US.UTF-8";
#           users.users.liyan = {
#             isNormalUser = true;
#             description = "Liyan";
#             home = "/home/liyan";
#             extraGroups = [ "wheel" "games" "video" "adbusers" "kvm" ];
#             shell = pkgs.zsh;
#           };
#           environment.systemPackages = with pkgs; [ git curl vim home-manager ];
#           programs.zsh.enable = true;
#           nix.settings = {
#             experimental-features = [ "nix-command" "flakes" ];
#             auto-optimise-store = true;
#           };
#           nix.gc = {
#             automatic = true;
#             dates = "weekly";
#             options = "--delete-older-than 7d";
#           };
#           powerManagement.enable = true;
#           hardware.bluetooth.enable = true;
#           services.blueman.enable = true;
#
#           # =================================================================
#           # BOOTLOADER (Diperbarui menggunakan GRUB sesuai file lama Anda)
#           # =================================================================
#           boot.loader.efi.canTouchEfiVariables = true;
#           boot.loader.grub = {
#             enable = true;
#             efiSupport = true;
#             device = "nodev"; # Penting untuk sistem EFI
#             useOSProber = false; # Lebih aman untuk tidak menggunakan os-prober
#             # Mempertahankan entri dual-boot Debian Anda
#             extraEntries = ''
#               menuentry "Debian" {
#                 search --fs-uuid --set=root 6ED1-C749
#                 chainloader /EFI/debian/shimx64.efi
#               }
#             '';
#           };
#
#           # =================================================================
#           # DRIVER NVIDIA
#           # =================================================================
#           boot.kernelPackages = pkgs.linuxPackages;
#           hardware.opengl.enable = true;
#           hardware.opengl.driSupport32Bit = true;
#           services.xserver.videoDrivers = [ "nvidia" ];
#           hardware.nvidia = {
#             modesetting.enable = true;
#             package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
#             nvidiaSettings = true;
#             open = false;
#             prime = {
#               sync.enable = true;
#               intelBusId = "PCI:0:2:0";
#               nvidiaBusId = "PCI:1:0:0";
#             };
#           };
#
#           system.stateVersion = "25.05";
#         })
#       ];
#     };
#   };
# }
