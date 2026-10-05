{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.customPowerManagement;
in
{
  # Define the options for this module
  options.customPowerManagement = {
    enable = mkEnableOption "comprehensive power management (TLP, auto-cpufreq, thermald, upower)";
  };

  # Apply the configuration if enabled
  config = mkIf cfg.enable {
    
    # --- Base Services ---
    services.upower.enable = true;
    # Note: Kept from your original snippet, though technically a hardware toggle
    hardware.bluetooth.enable = true; 

    # Disable conflicting power daemon
    services.power-profiles-daemon.enable = false;

    # --- TLP Configuration ---
    services.tlp = {
      enable = true;
      # Provides a power-profiles-daemon-like D-Bus interface for TLP
      pd.enable = true;

      settings = {
        # --------------------------------------------------
        # CPU management: fully delegated to auto-cpufreq.
        # --------------------------------------------------
        CPU_SCALING_GOVERNOR_ON_AC = "";
        CPU_SCALING_GOVERNOR_ON_BAT = "";
        CPU_ENERGY_PERF_POLICY_ON_AC = "";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "";
        CPU_MIN_FREQ_ON_AC = "";
        CPU_MAX_FREQ_ON_AC = "";
        CPU_MIN_FREQ_ON_BAT = "";
        CPU_MAX_FREQ_ON_BAT = "";
        CPU_BOOST_ON_AC = "";
        CPU_BOOST_ON_BAT = "";
        CPU_HWP_DYN_BOOST_ON_AC = "";
        CPU_HWP_DYN_BOOST_ON_BAT = "";
        SCHED_POWERSAVE_ON_AC = "";
        SCHED_POWERSAVE_ON_BAT = "";

        # --------------------------------------------------
        # PCIe Link Power Management
        # --------------------------------------------------
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersave";
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # --------------------------------------------------
        # Storage Power Management
        # --------------------------------------------------
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";
        AHCI_RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";

        # --------------------------------------------------
        # Legacy Disk Management
        # --------------------------------------------------
        DISK_APM_LEVEL_ON_AC = "254 254";
        DISK_APM_LEVEL_ON_BAT = "128 128";

        # --------------------------------------------------
        # Connectivity
        # --------------------------------------------------
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        WOL_DISABLE = "Y";

        # --------------------------------------------------
        # Audio
        # --------------------------------------------------
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 5;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # --------------------------------------------------
        # USB
        # --------------------------------------------------
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_BTUSB = 1;

        # --------------------------------------------------
        # TLP-RDW rules
        # --------------------------------------------------
        DEVICES_TO_DISABLE_ON_LAN_CONNECT = "wifi bluetooth";
        DEVICES_TO_ENABLE_ON_LAN_DISCONNECT = "wifi bluetooth";
        DEVICES_TO_DISABLE_ON_DOCK = "wifi bluetooth";
        DEVICES_TO_ENABLE_ON_UNDOCK = "wifi bluetooth";
      };
    };

    # --- Auto-cpufreq ---
    # Auto-cpufreq owns CPU frequency/governor/EPP/turbo.
    services.auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          energy_performance_preference = "performance";
          turbo = "auto";
        };
        battery = {
          governor = "powersave";
          energy_performance_preference = "power";
          turbo = "auto";
        };
      };
    };

    # --- Thermal Protection ---
    services.thermald.enable = true;
  };
}