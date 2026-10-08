# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/power-management.nix
      ./modules/ram-management.nix
      ./modules/networking_firewalls.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable hardware graphics
  hardware.graphics = {
    	enable = true;
    	enable32Bit = true;
    	extraPackages = with pkgs; [
      		intel-media-driver # For Broadwell (5th gen) or newer
      		libvdpau-va-gl
    	];
  };

  environment.sessionVariables = { 
  	LIBVA_DRIVER_NAME = "iHD"; 
    # Forcing electron based application to use hardware acceleration and screensharing
    ELECTRON_EXTRA_LAUNCH_ARGS = "--enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=WebRTCPipeWireCapturer";

  };

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # commenting out the above line

  #################
  # custom modules#
  #################

  # enabling custom power-management module
  customPowerManagement.enable = true;
  # enable custom ram-management module
  customMemManagement.enable = true;

  # starship prompt
  programs.starship.enable = true;
  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Dynamic Linker for unpatched binaries (VS Code extensions, Python wheels)
  programs.nix-ld.enable = true;

  #-------------- Mandatory stuff for noctalia----------------------
  security.polkit.enable = true;
  services.dbus.enable = true;

  xdg.portal = { 
	enable = true; 
	extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ]; 
	config.common.default = ["gnome" "gtk"];
  };
  security.rtkit.enable = true; 
  services.pipewire = { 
  	enable = true; 
	alsa.enable = true; 
	jack.enable = true; 
	pulse.enable = true;
  };

  # enabling niri
  programs.niri.enable = true;
  systemd.user.services.niri.enableDefaultPath = false;
  
  # enabling display Manager(ly)
  services.displayManager.ly = {
  	enable = true;
  	settings = {
  		animate = true;
	  	animation = "matrix";
        	hide_borders = true;
		bigclock = true;
   	};
  };

  # enabling noctalia as a systemd service
  programs.noctalia = {
  	enable = true;
	systemd = {
  		enable = true;
	};
  };
  # Configure keymap in X11
  services.xserver.xkb = {
    	layout = "us";
    	variant = "";
  };

  # enable zsh
  programs.zsh = {
  	enable = true;
	autosuggestions.enable = true;
	syntaxHighlighting.enable = true;
	enableCompletion = true;
  promptInit = ""; # stops the default zsh prompt to overwrite starship

  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."surya" = {
    	isNormalUser = true;
    	description = "Suryansh Sharma";
    	shell = pkgs.zsh;
    	extraGroups = [ "networkmanager" "wheel" "render" "video" "docker" "input" ];
    	packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # allow insecure packages
  nixpkgs.config.permittedInsecurePackages = [
  	"openssl-1.1.1w" # for sublime text
  ];

  # enable the synaptics driver for fingerprint
  # services.open-fprintd.enable = true;
  # services.python-validity.enable = true;
  # allow fingerprint authentication
  #security.pam.services.sudo.fprintAuth = true;
  #security.pam.services.login.fprintAuth = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    neovim
    fastfetch
    btop
    termdown
    kitty
    google-chrome
    vesktop
    telegram-desktop
    git
    nautilus
    devenv
    direnv
    vscode
    sublime4
    eza
    gnome-software
    papirus-icon-theme
    polkit_gnome
    usbutils
    brave
    brightnessctl
    proton-vpn
    xwayland-satellite
    wlsunset
    wl-clipboard
    fzf
    fd
    bat
    trash-cli
    zoxide
    ripgrep
    lazygit
    gh
    zsh-completions
  ];
  
  # Enabling native direnv integration
  programs.direnv.enable = true;

  # enable fonts
  fonts.packages = with pkgs; [
  	nerd-fonts.jetbrains-mono
	noto-fonts
	noto-fonts-color-emoji
	font-awesome
	liberation_ttf
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  # enabling flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  #------------------- optimize Nix Store--------------------
  nix.optimise.automatic = true;
  nix.optimise.dates = ["daily"];
  #------------------- enabling nh---------------------------\
  programs.nh = {
	enable = true;
	clean.enable = true;
	clean.extraArgs = "--keep 5 --keep-since 7d";
	flake = "/home/surya/nixos-config"; # Changed from /etc/nixos to point to your actual Git directory
  };

  #------------------- enabling docker-----------------------
  virtualisation.docker.enable = true;
  #--------------------enabling gvfs and udisks for nautilus-
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  #--------------------enabling gnome keyring ---------------
  services.gnome.gnome-keyring.enable = true;
  # enabling flatpak
  services.flatpak.enable = true;
  
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
