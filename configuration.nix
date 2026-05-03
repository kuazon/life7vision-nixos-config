# ============================================================
#  NixOS System Configuration — life7vision
#  Professional Developer Setup | Hyprland | AMD GPU
#  Updated: 2026-04 — Caddy subdomains, SSH hardening,
#           Fail2ban, Studio port fix, Supabase integration
# ============================================================
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nixos-dev-layout-snippet.nix
  ];

  # ──────────────────────────────────────────────────────────
  # BOOT
  # ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "amd_pstate=active"
    "quiet"
    "splash"
  ];

  # ──────────────────────────────────────────────────────────
  # ZRAM
  # ──────────────────────────────────────────────────────────
  zramSwap = {
    enable        = true;
    algorithm     = "zstd";
    memoryPercent = 25;
  };

  # ──────────────────────────────────────────────────────────
  # FILESYSTEMS
  # ──────────────────────────────────────────────────────────
  fileSystems."/mnt/portable-ssd" = {
    device  = "/dev/disk/by-uuid/f41cd052-b525-430a-8ea8-59a4e781e3b2";
    fsType  = "ext4";
    options = [ "nofail" "noatime" "x-systemd.device-timeout=10" ];
  };

  # ──────────────────────────────────────────────────────────
  # NETWORK
  # ──────────────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 2222 2424 ];
    # Docker container'lar arası iletişim için
    trustedInterfaces = [ "docker0" ];
  };

  networking.wireguard.enable = true;

  # ──────────────────────────────────────────────────────────
  # LOCALE & TIME
  # ──────────────────────────────────────────────────────────
  time.timeZone = "Europe/Istanbul";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME     = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
  };

  # ──────────────────────────────────────────────────────────
  # DISPLAY & SESSION
  # ──────────────────────────────────────────────────────────
  services.xserver.enable = true;
  services.xserver.xkb.layout = "tr";
  console.keyMap = "trq";

  services.displayManager.ly.enable = true;

 programs.hyprland = {
      enable          = true;
      xwayland.enable = true;
      package       = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

  # ──────────────────────────────────────────────────────────
  # LID SWITCH
  # ──────────────────────────────────────────────────────────
  services.logind = {
    lidSwitch              = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked        = "ignore";
  };

  # ──────────────────────────────────────────────────────────
  # AMD GPU
  # ──────────────────────────────────────────────────────────
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      rocmPackages.clr
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.mesa
    ];
  };

  environment.variables.AMD_VULKAN_ICD = "RADV";

  # ──────────────────────────────────────────────────────────
  # SOUND — PipeWire
  # ──────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    pulse.enable      = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    jack.enable       = true;
    wireplumber.enable = true;
  };

  # ──────────────────────────────────────────────────────────
  # SSH — hardened
  # ──────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    ports  = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
      X11Forwarding          = false;
      MaxAuthTries           = 3;
      LoginGraceTime         = 20;
    };
  };

  # ──────────────────────────────────────────────────────────
  # FAIL2BAN — brute force koruması
  # ──────────────────────────────────────────────────────────
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime  = "1h";
    jails = {
      ssh = {
        settings = {
          enabled  = true;
          port     = "2222";
          filter   = "sshd";
          maxretry = 3;
          bantime  = "24h";
        };
      };
    };
  };

  # ──────────────────────────────────────────────────────────
  # CADDY — reverse proxy + otomatik SSL
  # ──────────────────────────────────────────────────────────
  services.caddy = {
    enable = true;
    virtualHosts = {
      "git.kuazon.com".extraConfig = ''
        reverse_proxy 127.0.0.1:8929
      '';
      "accounts.kuazon.com".extraConfig = ''
        reverse_proxy 127.0.0.1:8080
      '';
      "db.kuazon.com".extraConfig = ''
        reverse_proxy 127.0.0.1:8000
      '';
      "studio.kuazon.com".extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
      "trading.kuazon.com".extraConfig = ''
        reverse_proxy 127.0.0.1:3001
      '';
    };
  };

  # ──────────────────────────────────────────────────────────
  # SYSTEM SERVICES
  # ──────────────────────────────────────────────────────────
  services.upower.enable                  = true;
  services.power-profiles-daemon.enable   = true;
  services.udisks2.enable                 = true;
  services.gvfs.enable                    = true;
  services.tumbler.enable                 = true;

  hardware.bluetooth = {
    enable       = true;
    powerOnBoot  = true;
  };
  services.blueman.enable = true;

  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };

  # ──────────────────────────────────────────────────────────
  # SECURITY
  # ──────────────────────────────────────────────────────────
  security.polkit.enable                = true;
  security.pam.services.hyprlock        = {};
  security.sudo.wheelNeedsPassword      = true;

  # ──────────────────────────────────────────────────────────
  # FONTS
  # ──────────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.meslo-lg
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      font-awesome
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif  = [ "Noto Sans" ];
        serif      = [ "Noto Serif" ];
      };
    };
  };

  # ──────────────────────────────────────────────────────────
  # USER
  # ──────────────────────────────────────────────────────────
  users.users.life7vision = {
    isNormalUser = true;
    description  = "carpio";
    shell        = pkgs.zsh;
    extraGroups  = [
      "networkmanager" "wheel" "docker"
      "audio" "video" "input" "storage"
      "render" "kvm" "libvirtd"
    ];
  };

  # ──────────────────────────────────────────────────────────
  # PROGRAMS
  # ──────────────────────────────────────────────────────────
  programs.dconf.enable   = true;
  programs.firefox.enable = true;
  programs.nix-ld.enable  = true;
  programs.gamemode.enable = true;

  # ──────────────────────────────────────────────────────────
  # SYSTEM PACKAGES
  # ──────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    # ── Tarayıcılar ─────────────────────────────────────────
    brave
    chromium

    # ── Editörler ───────────────────────────────────────────
    neovim
    vscode
    nano
    micro
    antigravity

    # ── Terminal ────────────────────────────────────────────
    kitty
    tmux
    zellij

    # ── Shell & Prompt ──────────────────────────────────────
    zsh
    oh-my-zsh
    starship
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-history-substring-search

    # ── Modern CLI Araçları ─────────────────────────────────
    eza bat fd ripgrep fzf zoxide delta dust duf procs
    bottom htop btop ncdu tokei hyperfine
    jq yq gron tldr curl wget httpie xh
    aria2 tree unzip zip p7zip rsync pv moreutils
    nushell lnav

    # ── Arşiv / Sıkıştırma ──────────────────────────────────
    zstd lz4 brotli

    # ── Git & Versiyon Kontrolü ─────────────────────────────
    git gh lazygit gitui git-lfs tig git-crypt gitleaks

    # ── Build Araçları ──────────────────────────────────────
    gcc clang gnumake cmake ninja meson
    pkg-config autoconf automake libtool just

    # ── Geliştirme Yardımcıları ─────────────────────────────
    watchexec entr direnv

    # ── Debug & Profiling ───────────────────────────────────
    gdb lldb valgrind strace ltrace perf

    # ── Python ──────────────────────────────────────────────
    (python3.withPackages (ps: with ps; [
      pip setuptools wheel virtualenv
      anthropic google-auth huggingface-hub
      transformers torch datasets tokenizers
      accelerate numpy pandas scikit-learn
      matplotlib jupyter ipython requests
      tqdm pyyaml plotly seaborn pillow
      scipy sympy pyarrow polars duckdb
      sqlalchemy psycopg2 redis
    ]))
    uv ruff poetry pipenv

    # ── Node.js ─────────────────────────────────────────────
    nodejs yarn pnpm bun

    # ── Go ──────────────────────────────────────────────────
    go gopls delve

    # ── Rust ────────────────────────────────────────────────
    rustup

    # ── Java ────────────────────────────────────────────────
    jdk

    # ── Lua ─────────────────────────────────────────────────
    lua luarocks

    # ── R ───────────────────────────────────────────────────
    R rPackages.tidyverse rPackages.ggplot2

    # ── LSP / Linter / Formatter ────────────────────────────
    nil nixfmt-rfc-style
    typescript-language-server
    vscode-langservers-extracted
    pyright marksman yaml-language-server
    taplo bash-language-server shellcheck shfmt

    # ── Nix Araçları ────────────────────────────────────────
    nh nix-output-monitor nvd nix-tree cachix nix-search-cli statix deadnix sops age

    # ── Cloud & AI CLI ──────────────────────────────────────
    google-cloud-sdk rclone awscli2 s3cmd

    # ── Database CLI ────────────────────────────────────────
    postgresql redis sqlite

    # ── Konteyner & DevOps ──────────────────────────────────
    docker-compose kubectl kubectx k9s helm
    terraform ansible bubblewrap

    # ── Ağ Araçları ─────────────────────────────────────────
    nmap netcat-gnu traceroute dig inetutils
    tcpdump bandwhich cloudflared wireguard-tools
    openvpn mtr iperf3 socat sshfs

    # ── Sistem Araçları ─────────────────────────────────────
    lshw inxi pciutils usbutils smartmontools
    lm_sensors nvme-cli sysstat
    man-pages man-pages-posix
    xdg-utils desktop-file-utils shared-mime-info

    # ── AMD GPU ─────────────────────────────────────────────
    vulkan-tools vulkan-loader libva libva-utils
    radeontop nvtopPackages.amd

    # ── Hyprland Ekosistemi ─────────────────────────────────
    wofi grim slurp wl-clipboard cliphist
    hyprpaper hyprlock hypridle hyprpicker
    swww waypaper wf-recorder brightnessctl
    playerctl pavucontrol networkmanagerapplet
    nwg-look libsForQt5.qt5ct kdePackages.qt6ct
    quickshell imagemagick gnuplot

    # ── Dosya Yönetimi ──────────────────────────────────────
    yazi ranger nautilus file-roller

    # ── Medya ───────────────────────────────────────────────
    mpv imv ffmpeg

    # ── Güvenlik & Şifreleme ────────────────────────────────
    gnupg age pass bitwarden-cli openssl _1password-cli

    # ── Android
    android-tools

    # ── Genel Uygulamalar ───────────────────────────────────
    libreoffice obsidian qbittorrent
    virt-manager telegram-desktop
  ];

  # ──────────────────────────────────────────────────────────
  # VIRTUALISATION
  # ──────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable       = true;
    enableOnBoot = true;
    daemon.settings = {
      "data-root"      = "/mnt/portable-ssd/docker";
      "storage-driver" = "overlay2";
      log-driver       = "json-file";
      log-opts         = { max-size = "10m"; max-file = "3"; };
    };
  };

  systemd.services.docker = {
    after    = [ "mnt-portable\\x2dssd.mount" ];
    requires = [ "mnt-portable\\x2dssd.mount" ];
  };

  virtualisation.libvirtd.enable = true;

  # ──────────────────────────────────────────────────────────
  # SYSTEMD — tmpfiles & servisler
  # ──────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /mnt/portable-ssd/backups 0755 life7vision users - -"
    "d /mnt/portable-ssd/backups/gitea 0750 life7vision users - -"
    "d /mnt/portable-ssd/backups/logs 0750 life7vision users - -"
  ];

  systemd.services.gitea-portable-backup = {
    description = "Backup the portable SSD Gitea instance";
    after    = [ "docker.service" "mnt-portable\\x2dssd.mount" ];
    requires = [ "docker.service" "mnt-portable\\x2dssd.mount" ];
    path = with pkgs; [
      bash coreutils docker findutils gnugrep util-linux
    ];
    serviceConfig = {
      Type                 = "oneshot";
      User                 = "life7vision";
      Group                = "users";
      SupplementaryGroups  = [ "docker" ];
      UMask                = "0027";
      Nice                 = 10;
      IOSchedulingClass    = "best-effort";
      IOSchedulingPriority = 7;
    };
    script = ''exec /home/life7vision/Ops/scripts/backup_gitea_portable.sh'';
  };

  systemd.timers.gitea-portable-backup = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnCalendar         = "*-*-* 03:20:00";
      Persistent         = true;
      RandomizedDelaySec = "15m";
      Unit               = "gitea-portable-backup.service";
    };
  };

  systemd.services.gitea-portable-offsite-sync = {
    description = "Copy portable SSD Gitea backups to Google Drive";
    after   = [
      "network-online.target"
      "mnt-portable\\x2dssd.mount"
      "gitea-portable-backup.service"
    ];
    wants    = [ "network-online.target" ];
    requires = [ "mnt-portable\\x2dssd.mount" ];
    path = with pkgs; [
      bash coreutils findutils gnugrep rclone util-linux
    ];
    serviceConfig = {
      Type                 = "oneshot";
      User                 = "life7vision";
      Group                = "users";
      UMask                = "0027";
      Nice                 = 10;
      IOSchedulingClass    = "best-effort";
      IOSchedulingPriority = 7;
    };
    script = ''exec /home/life7vision/Ops/scripts/sync_gitea_backups_gdrive.sh'';
  };

  systemd.timers.gitea-portable-offsite-sync = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnCalendar         = "*-*-* 03:50:00";
      Persistent         = true;
      RandomizedDelaySec = "15m";
      Unit               = "gitea-portable-offsite-sync.service";
    };
  };

  systemd.services.portable-ssd-healthcheck = {
    description = "Collect portable SSD health and storage diagnostics";
    after    = [ "docker.service" "mnt-portable\\x2dssd.mount" ];
    requires = [ "mnt-portable\\x2dssd.mount" ];
    path = with pkgs; [
      bash coreutils docker findutils gnugrep
      smartmontools systemd util-linux
    ];
    serviceConfig = {
      Type                 = "oneshot";
      User                 = "root";
      Group                = "users";
      UMask                = "0027";
      Nice                 = 10;
      IOSchedulingClass    = "best-effort";
      IOSchedulingPriority = 7;
    };
    script = ''exec /home/life7vision/Ops/scripts/portable_ssd_healthcheck.sh'';
  };

  systemd.timers.portable-ssd-healthcheck = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnCalendar         = "*-*-* 04:10:00";
      Persistent         = true;
      RandomizedDelaySec = "20m";
      Unit               = "portable-ssd-healthcheck.service";
    };
  };

  # ──────────────────────────────────────────────────────────
  # ZSH
  # ──────────────────────────────────────────────────────────
  programs.zsh = {
    enable            = true;
    enableCompletion  = true;
    autosuggestions.enable     = true;
    syntaxHighlighting.enable  = true;
    ohMyZsh = {
      enable  = true;
      plugins = [
        "git" "docker" "kubectl" "python"
        "rust" "golang" "fzf" "z" "sudo"
        "colored-man-pages" "copypath" "copyfile"
        "direnv"
      ];
    };
    shellAliases = {
      ls    = "eza --icons";
      ll    = "eza -la --icons --git";
      la    = "eza -a --icons";
      lt    = "eza --tree --icons";
      cat   = "bat";
      grep  = "rg";
      find  = "fd";
      ps    = "procs";
      top   = "btm";
      du    = "dust";
      df    = "duf";
      cd    = "z";

      rebuild = "nh os switch /etc/nixos";
      update  = "sudo nix flake update /etc/nixos && nh os switch /etc/nixos";
      cleanup = "sudo nix-collect-garbage --delete-older-than 14d";
      gcroot  = "sudo nix-collect-garbage -d";
      editnix = "sudo nvim /etc/nixos/configuration.nix";
      nixlog  = "journalctl -u nixos-rebuild -f";
      nixdiff = "nvd diff /run/booted-system /run/current-system";

      g   = "git";
      lg  = "lazygit";
      gst = "git status";
      gaa = "git add -A";
      gcm = "git commit -m";
      gps = "git push";
      gpl = "git pull";
      gd  = "git diff";
      gl  = "git log --oneline --graph --decorate";

      dc  = "docker-compose";
      dps = "docker ps";
      di  = "docker images";
      dex = "docker exec -it";

      ssd    = "cd /mnt/portable-ssd";
      dkdata = "cd /mnt/portable-ssd/docker";
      dkproj = "cd /mnt/portable-ssd/projects";

      rc  = "rclone";
      rcs = "rclone sync";
      rcp = "rclone copy --progress";

      gc     = "gcloud";
      gcl    = "gcloud projects list";
      gca    = "gcloud auth login";
      gcconf = "gcloud config list";

      pg  = "psql";
      rd  = "redis-cli";

      v   = "nvim";
      vim = "nvim";
      nv  = "nvim";
      q   = "exit";
      clr = "clear";
      py  = "python3";
    };
    interactiveShellInit = ''
      eval "$(zoxide init zsh)"
      eval "$(starship init zsh)"
      eval "$(direnv hook zsh)"
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/go/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.npm-global/bin:$PATH"

      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      [[ -f "$HOME/.config/life7vision/secrets" ]] && source "$HOME/.config/life7vision/secrets"
    '';
  };

  # ──────────────────────────────────────────────────────────
  # ENVIRONMENT
  # ──────────────────────────────────────────────────────────
  environment.variables = {
    EDITOR    = "nvim";
    VISUAL    = "nvim";
    PAGER     = "bat";
    MANPAGER  = "sh -c 'col -bx | bat -l man -p'";
    BAT_THEME = "Catppuccin-mocha";

    COMPOSE_FILE_DIR = "/mnt/portable-ssd/projects";
    CLOUDSDK_PYTHON  = "${pkgs.python3}/bin/python3";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM    = "wayland";
    SDL_VIDEODRIVER    = "wayland";
    CLUTTER_BACKEND    = "wayland";
  };

  # ──────────────────────────────────────────────────────────
  # NIX SETTINGS
  # ──────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
    trusted-users         = [ "root" "life7vision" ];
    keep-outputs          = true;
    keep-derivations      = true;
    max-jobs              = "auto";
    cores                 = 0;
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSBd8="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  # ──────────────────────────────────────────────────────────
  # STATE VERSION
  # ──────────────────────────────────────────────────────────
  system.stateVersion = "25.11";
}
