{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos"; # Define your hostname.
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd"; # Force NetworkManager to use iwd backend
  networking.wireless.enable = false; # Force wpa_supplicant to be off

  # Enable the iwd daemon itself
  networking.wireless.iwd = {
      enable = true;
      settings = {
          Settings = {
            AutoConnect = true;
          };
          General = {
            AddressRandomization = "network"; # Randomize MAC address per network for privacy
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
      rejectPackets = false; # Drop packets silently
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
      allowedTCPPorts = [];
      checkReversePath = "loose";
  };
}