{ config, pkgs, lib, ... }:

let
  niriConfigDir = "${config.home.homeDirectory}/.config/niri";
  kittyConfigDir = "${config.home.homeDirectory}/.config/kitty";
in
{
  home.username = "surya";
  home.homeDirectory = "/home/surya";

  # Do not touch this value no matter what !!! ◣_◢
  home.stateVersion = "24.05";

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };

  # ===============================
  # Git & GitHub CLI Configuration 
  # ===============================
  
  programs.git = {
    enable = true;
    lfs.enable = true;

      settings = {
      init = {
        defaultBranch = "main";
      };
      include = {
        path = "${config.home.homeDirectory}/.gitconfig.local";
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.home-manager.enable = true;
}
