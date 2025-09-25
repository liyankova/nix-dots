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
  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: {
    nixosConfigurations.laptop-hp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs; 
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
	};
      };

      modules = [
        ./hardware-configuration.nix
        ({ config, pkgs, lib, pkgs-unstable, ... }: 
        let
          # Define unstable packages for easier access.
          pkgs-unstable = import nixpkgs-unstable {
            system = pkgs.system;
            config.allowUnfree = true;
          };

          # Overlay to replace stable hyprland with the unstable version.
          hyprland-overlay = final: prev: {
            hyprland = pkgs-unstable.hyprland;
          };
        in
        {
          # Apply the overlay to the entire system configuration.
          nixpkgs.overlays = [ hyprland-overlay ];
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
          environment.systemPackages = with pkgs; [ 
	     git curl vim home-manager 
	  ];
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
          # sound.enable = false;

          # Display Manager (Login Screen)
          services.libinput.enable = true;
          services.displayManager = {
            sddm.enable = true;
	    sddm.wayland.enable = true;
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

          # Enable XDG Portals for Flatpak and Wayland integration.
          xdg.portal = {
            enable = true;
	    config.common.default = "*";
            extraPortals = with pkgs; [
              xdg-desktop-portal-gtk
              # pkgs-unstable.xdg-desktop-portal-hyprland
            ];
          };
	  programs.hyprland.enable = true;

	  programs.adb.enable = true;

	  services.openssh.enable = true;
          age.secrets.example-secret = {
            file = ./secrets/example-secret.age;
            owner = config.users.users.liyan.name; 
          };
          system.stateVersion = "25.05";
        })
      ];
    };
  };
}

