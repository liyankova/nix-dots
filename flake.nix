{
  description = "Konfigurasi NixOS Liyan - Langkah Migrasi 1";

  # =========================================================================
  # 1. INPUTS: Dependensi eksternal
  # =========================================================================
  inputs = {
    # Stabil untuk sistem & Home Manager
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # Unstable untuk aplikasi modern nanti
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home Manager sekarang mengikuti STABLE untuk fondasi yang lebih kokoh
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Kita siapkan inputnya untuk langkah selanjutnya
    hyprland.url = "github:hyprwm/Hyprland";
    agenix.url = "github:ryantm/agenix";
  };

  # =========================================================================
  # 2. CACHING: Optimisasi bandwidth (diambil dari best practice Perplexity)
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
      
      # specialArgs akan kita gunakan lebih banyak saat sudah modular
      specialArgs = { inherit inputs; };

      modules = [
        # Ini adalah satu-satunya file eksternal yang kita impor saat ini
        ./hardware-configuration.nix

        # Semua konfigurasi lainnya kita letakkan di sini secara langsung
        ({ config, pkgs, ... }: {
          
          # =================================================================
          # PENGATURAN INTI SISTEM (dari core.nix lama)
          # =================================================================
          
          # Waktu & Bahasa
          time.timeZone = "Asia/Jakarta";
          i18n.defaultLocale = "en_US.UTF-8";

          # Definisi User
          users.users.liyan = {
            isNormalUser = true;
            description = "Liyan";
            home = "/home/liyan";
            extraGroups = [ "wheel" "games" "video" "adbusers" "kvm" ];
            shell = pkgs.zsh;
          };

          # Paket-paket dasar yang harus ada di sistem
          environment.systemPackages = with pkgs; [
            git
            curl
            vim
            home-manager # Penting agar perintah `home-manager` tersedia
          ];
          
          # Mengaktifkan ZSH sebagai shell sistem
          programs.zsh.enable = true;

          # Pengaturan Nix (diambil dari core.nix dan disempurnakan)
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
          };
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          # Power Management & Bluetooth
          powerManagement.enable = true;
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;

          # =================================================================
          # BOOTLOADER (Asumsi systemd-boot, mohon konfirmasi)
          # =================================================================
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
   enable = true;
   efiSupport = true;
   # version = 2;
   device = "nodev";
   useOSProber = false;
  };
  # boot.kernelPackages = pkgs.linuxPackages;

  boot.loader.grub.extraEntries = ''
    menuentry "Debian" {
      search --fs-uuid --set=root 6ED1-C749
      chainloader /EFI/debian/shimx64.efi
  }
  '';          # =================================================================
          # DRIVER NVIDIA (Implementasi best practice)
          # =================================================================
          
          # Menggunakan kernel LTS untuk stabilitas driver legacy
          boot.kernelPackages = pkgs.linuxPackages_lts;

          # Mengaktifkan OpenGL
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
              # Bus ID ini mungkin perlu disesuaikan, tapi biasanya ini defaultnya
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
          };

          # Versi sistem untuk NixOS
          system.stateVersion = "25.05";
        })
      ];
    };
  };
}
