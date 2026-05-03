# ============================================================
#  Home-Manager — life7vision kullanıcı konfigürasyonu
#  Hyprland dotfiles'a DOKUNULMAZ — sadece user araçları
# ============================================================
{ config, pkgs, inputs, ... }:
{
  home.username      = "life7vision";
  home.homeDirectory = "/home/life7vision";
  home.stateVersion  = "25.11";   # system ile aynı olmalı

  # ──────────────────────────────────────────────────────────
  # Kullanıcı Paketleri
  # (system-wide olması gerekmeyen araçlar buraya)
  # ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # Nix araçları
    nix-tree          # bağımlılık ağacı görselleştirici
    nix-du            # nix store disk kullanımı
    nvd               # iki nesil arası diff

    # Python araçları (kullanıcı bazlı)
    python3Packages.ipython
    python3Packages.requests

    # Yardımcı araçlar
    wtype             # wayland keyboard input simulator
    wev               # wayland event viewer (keybind debug)
    xdg-utils
  ];

  # ──────────────────────────────────────────────────────────
  # Git
  # ──────────────────────────────────────────────────────────
  programs.git = {
        enable = true;
        package = pkgs.gitFull;
        userName = "Ramazan Ermis";
        userEmail = "life7vision@outlook.com";
  
        lfs.enable = true;
        delta.enable = true;
  
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          rebase.autoStash = true;
          fetch.prune = true;
          push.autoSetupRemote = true;
          core.editor = "code --wait";
          core.autocrlf = "input";
          core.fileMode = false;
          credential.helper = "store";
          merge.conflictStyle = "zdiff3";
          rerere.enabled = true;
          safe.directory = "/etc/nixos";
        };
      };

  # ──────────────────────────────────────────────────────────
  # Starship Prompt
  # ──────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❄](bold blue)";
        error_symbol   = "[✗](bold red)";
      };
      directory = {
        truncation_length = 3;
        style = "bold cyan";
      };
      git_branch.symbol  = " ";
      nix_shell.symbol   = "❄ ";
      rust.symbol        = " ";
      python.symbol      = " ";
      golang.symbol      = " ";
      nodejs.symbol      = " ";
    };
  };

  # ──────────────────────────────────────────────────────────
  # Zoxide
  # ──────────────────────────────────────────────────────────
  programs.zoxide = {
    enable            = true;
    enableZshIntegration = true;
  };

  # ──────────────────────────────────────────────────────────
  # fzf
  # ──────────────────────────────────────────────────────────
  programs.fzf = {
    enable               = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--border"
      "--layout=reverse"
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
  };

  # ──────────────────────────────────────────────────────────
  # Bat (cat yerine)
  # ──────────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config = {
      theme  = "Catppuccin-mocha";
      style  = "numbers,changes,header";
      pager  = "less -FR";
    };
  };

  # ──────────────────────────────────────────────────────────
  # Kitty Terminal
  # ──────────────────────────────────────────────────────────
  programs.kitty = {
    enable   = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      scrollback_lines     = 10000;
      enable_audio_bell    = false;
      update_check_interval = 0;
      confirm_os_window_close = 0;
      # Catppuccin Mocha renk şeması
      foreground           = "#cdd6f4";
      background           = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
      cursor               = "#f5e0dc";
      cursor_text_color    = "#1e1e2e";
    };
  };

  # ──────────────────────────────────────────────────────────
  # XDG dizin standartları
  # ──────────────────────────────────────────────────────────
  xdg = {
    enable = true;
    userDirs = {
      enable        = true;
      createDirectories = true;
      desktop       = "${config.home.homeDirectory}/Desktop";
      documents     = "${config.home.homeDirectory}/Documents";
      download      = "${config.home.homeDirectory}/Downloads";
      music         = "${config.home.homeDirectory}/Music";
      pictures      = "${config.home.homeDirectory}/Pictures";
      videos        = "${config.home.homeDirectory}/Videos";
      templates     = "${config.home.homeDirectory}/Templates";
      publicShare   = "${config.home.homeDirectory}/Public";
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain"       = "nvim.desktop";
        "image/*"          = "imv.desktop";
        "video/*"          = "mpv.desktop";
        "application/pdf"  = "firefox.desktop";
      };
    };
  };

  # ──────────────────────────────────────────────────────────
  # NPM Global Prefix (NixOS store read-only olduğu için)
  # ──────────────────────────────────────────────────────────
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.file.".npmrc".text = ''
    prefix=''${HOME}/.npm-global
  '';
  # ~/.config/hypr/ tamamen senin kontrolünde kalır
  # home-manager buraya müdahale etmez
  # ──────────────────────────────────────────────────────────

  # Home-manager kendi kendini yönetsin
  programs.home-manager.enable = true;
}
