{ config, pkgs, ... }:

{
  home.username = "surya";
  home.homeDirectory = "/home/surya";

  # Do not touch this value no matter what !!! ◣_◢
  home.stateVersion = "24.05"; 

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  
   # Manage the global cursor theme for GTK and X11 apps
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
   

  # creates the default directories,
  xdg.userDirs = {
      enable = true;
      createDirectories = true;
  };


  programs.home-manager.enable = true;
}
