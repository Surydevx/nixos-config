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
    setSessionVariables = true; # Silences the 26.05 deprecation warning log
  };

  # ===========================================================
  # Git & GitHub CLI Configuration (Absolute Inclusion Fix)
  # ===========================================================
  programs.git = {
    enable = true;
    lfs.enable = true;

      includes = [
        { path = "~/.gitconfig.local"; }
    ];

  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # ===========================================================
  # Seed Niri config from dotfiles/niri/config.kdl
  # ===========================================================
  home.activation.seedNiriConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${niriConfigDir}"

    if [ -L "${niriConfigDir}/config.kdl" ]; then
      rm "${niriConfigDir}/config.kdl"
    fi

    if [ ! -f "${niriConfigDir}/config.kdl" ]; then
      echo "Seeding Niri config from dotfiles/niri/config.kdl..."
      cp ${./dotfiles/niri/config.kdl} "${niriConfigDir}/config.kdl"
      chmod u+w "${niriConfigDir}/config.kdl"
    else
      echo "Niri config already exists. Halting Copy."
    fi
  '';

  # ===========================================================
  # Seed Kitty config from dotfiles/kitty/kitty.conf
  # ===========================================================
  home.activation.seedKittyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${kittyConfigDir}"

    if [ -L "${kittyConfigDir}/kitty.conf" ]; then
      rm "${kittyConfigDir}/kitty.conf"
    fi

    if [ ! -f "${kittyConfigDir}/kitty.conf" ]; then
      echo "Seeding Kitty config from dotfiles/kitty/kitty.conf..."
      cp ${./dotfiles/kitty/kitty.conf} "${kittyConfigDir}/kitty.conf"
      chmod u+w "${kittyConfigDir}/kitty.conf"
    else
      echo "Kitty config already exists. Halting Copy."
    fi
  '';

  programs.home-manager.enable = true;
}
