{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd"; # Force NetworkManager to use iwd backend
  networking.wireless.enable = false; # Force wpa_supplicant to be off

  #  NetworkManager will handle MAC randomization safely per connection
  networking.networkmanager.settings = {
    "device" = {
      "wifi.scan-rand-mac-address" = "yes";
    };
    "connection" = {
      "wifi.cloned-mac-address" = "random";
    };
  };

  # Enable the iwd daemon itself
  networking.wireless.iwd = {
      enable = true;
      settings = {
          Settings = {
            AutoConnect = true;
          };
          General = {
            # 💡 FIXED: Set this to "none" so iwd doesn't fight NetworkManager
            AddressRandomization = "none"; 
          };
      };
  };

  # Enable Tailscale
  services.tailscale.enable = true;

  # Enable firewall
  networking.nftables.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
      enable = true;
      rejectPackets = false; # Drop packets silently w/o rejecting
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
      allowedTCPPorts = [];
      checkReversePath = "loose";
  };
}
