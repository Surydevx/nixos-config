{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.customMemManagement;
in
{
  # Define the options for this module
  options.customMemManagement = {
    enable = mkEnableOption "advanced RAM, ZRAM, and swap management";
  };

  # Apply the configuration if enabled
  config = mkIf cfg.enable {
    
    # Disable standard systemd-generated swap devices
    swapDevices = mkForce [ ];

    boot.kernelParams = [
      "systemd.swap=0"               
      "psi=1"                        
      "transparent_hugepage=madvise" 
    ];

    # ZRAM configuration with dedicated SSD backing
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 85;            
      writebackDevice = "/dev/disk/by-partuuid/4a45f1ab-a8d0-4236-b32d-4bba4e4f1f93";
    };

    # Explicitly force-enable all MGLRU components safely via tmpfiles
    systemd.tmpfiles.rules = [
      "w /sys/kernel/mm/lru_gen/enabled - - - - y"
    ];

    # Fail-Safe Maintenance Script
    systemd.services.zram-flush = {
      description = "ZRAM maintenance: flush cold pages back to SSD partition";
      requires = [ "dev-zram0.device" ];
      after = [ "dev-zram0.device" "swap.target" ];
      wants = [ "swap.target" ];     
      unitConfig.ConditionPathExists = "/sys/block/zram0/writeback";
      serviceConfig.Type = "oneshot";
      
      script = ''
        zr=/sys/block/zram0
        age=1800 # 30 mins

        # Safety check for missing backing device attachment
        if [ "$(cat $zr/backing_dev)" = "none" ]; then
          echo "zram0 has no backing_dev linked; exiting" >&2
          exit 0
        fi

        # 1. Set explicit per-run write budget: 512 MiB in 4K page blocks (131072 pages)
        echo 0 > $zr/writeback_limit_enable || true
        echo 131072 > $zr/writeback_limit || true
        echo 1 > $zr/writeback_limit_enable || true

        # 2. Determine and apply appropriate page identification routine
        # Guard against uptime underflow regression and missing ACTIME config
        if [ "$(cut -d. -f1 /proc/uptime)" -gt "$age" ] && echo "$age" > $zr/idle 2>/dev/null; then
          echo "[zram-flush] Age mode active: writing back pages untouched for $age seconds"
          echo idle > $zr/writeback || true
        else
          # Fallback: Mark everything idle now; swept out on the NEXT hourly run
          echo "[zram-flush] Classic mode active: writing back pages untouched since last run"
          echo idle > $zr/writeback || true
          echo all > $zr/idle || true
        fi

        # 3. Defragment ZRAM storage spaces to consolidate freed blocks
        echo 1 > $zr/compact || true
      '';
    };

    # Monotonic Maintenance Timer
    systemd.timers.zram-flush = {
      description = "Hourly ZRAM maintenance and writeback loop";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10m";
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "5m";   
      };
    };

    # Safe Systemd OOMD Policy
    systemd.oomd = {
      enable = true;
      enableRootSlice = false;       
      enableUserSlices = true;       
    };

    # Optimized VM Virtual Memory Adjustments
    boot.kernel.sysctl = {
      "vm.swappiness" = 111;         
      "vm.watermark_boost_factor" = 0; 
      "vm.watermark_scale_factor" = 125; 
      "vm.page-cluster" = 0;         
    };

    # File System Maintenance
    services.fstrim.enable = true;   
  };
}