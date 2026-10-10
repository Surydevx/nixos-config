{ config, lib, pkgs, ... }:

let
  cfg = config.customMemManagement;

  writebackDevice =
    if cfg.writebackDevice != null
    then cfg.writebackDevice
    else "/dev/disk/by-partlabel/${cfg.writebackPartitionLabel}";

  zramSysPath = "/sys/block/zram0";
in
{
  options.customMemManagement = {
    enable = lib.mkEnableOption "advanced RAM, ZRAM, and swap management";

    writebackPartitionLabel = lib.mkOption {
      type = lib.types.str;
      default = "zram-writeback";
      description = ''
        Partition label used to find the ZRAM writeback partition.
        The module will use /dev/disk/by-partlabel/<label> by default.
      '';
    };

    writebackDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Explicit writeback block device path (e.g., /dev/disk/by-partuuid/...).
        If null, the module uses the partition label option instead.
      '';
    };

    attachWritebackDevice = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to attach a writeback device to ZRAM.
        Disable this if you do not have a dedicated writeback partition.
      '';
    };

    memoryPercent = lib.mkOption {
      type = lib.types.int;
      default = 85;
      description = "ZRAM size as a percentage of physical RAM.";
    };

    flushAgeSeconds = lib.mkOption {
      type = lib.types.int;
      default = 1800;
      description = "Idle age threshold in seconds used for ZRAM writeback flushes.";
    };

    writebackLimitPages = lib.mkOption {
      type = lib.types.int;
      default = 131072;
      description = ''
        Writeback budget per maintenance run in 4K pages.
        131072 pages = 512 MiB.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion =
          cfg.writebackDevice == null
          || lib.hasPrefix "/" cfg.writebackDevice;
        message = ''
          customMemManagement.writebackDevice must be an absolute block device path,
          for example: /dev/disk/by-partlabel/zram-writeback or /dev/disk/by-partuuid/...
        '';
      }
    ];

    # ------------------------------------------------------------
    # Absolute Swap Overrides
    # ------------------------------------------------------------
    swapDevices = lib.mkForce [ ];

    boot.kernelParams = [
      "systemd.swap=0"               # Block systemd from auto-activating arbitrary swaps
      "psi=1"                        # Pressure Stall Information for systemd-oomd
      "transparent_hugepage=madvise" # Restricts THP usage to prevent desktop memory bloat
    ];

    # ------------------------------------------------------------
    # ZRAM Configuration
    # ------------------------------------------------------------
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.memoryPercent;
      # FIX: Native assignment ensures the backing device attaches BEFORE swapon runs
      writebackDevice = lib.mkIf cfg.attachWritebackDevice writebackDevice;
    };

    # ------------------------------------------------------------
    # Kernel Feature Activations (MGLRU)
    # ------------------------------------------------------------
    systemd.tmpfiles.rules = [
      "w /sys/kernel/mm/lru_gen/enabled - - - - y"
    ];

    # ------------------------------------------------------------
    # Refactored ZRAM Maintenance & Writeback Service
    # ------------------------------------------------------------
    systemd.services.zram-flush = lib.mkIf cfg.attachWritebackDevice {
      description = "ZRAM maintenance: flush cold pages back to backing device";

      requires = [ "dev-zram0.device" ];
      after = [ "dev-zram0.device" "swap.target" ];

      unitConfig.ConditionPathExists = "${zramSysPath}/writeback";

      serviceConfig = {
        Type = "oneshot";
        # FIX: Puts the maintenance work in the background to prevent desktop frame drops
        IOSchedulingClass = "idle";
        CPUSchedulingPolicy = "idle";
      };
      
      path = [ pkgs.coreutils ];

      script = ''
        zr="${zramSysPath}"
        age="${toString cfg.flushAgeSeconds}"
        limit="${toString cfg.writebackLimitPages}"

        # FIX: Check native attachment status safely; eliminate impossible runtime hot-plugging
        if [ "$(cat "$zr/backing_dev" 2>/dev/null)" = "none" ] || [ ! -f "$zr/writeback" ]; then
          echo "[zram-flush] Error: No backing device bound to ZRAM engine. Exiting." >&2
          exit 1
        fi

        # 1. Establish strict budget boundaries
        echo 0 > "$zr/writeback_limit_enable" || true
        echo "$limit" > "$zr/writeback_limit" || true
        echo 1 > "$zr/writeback_limit_enable" || true

        # 2. Determine and apply appropriate page identification routine
        uptime_seconds=$(cut -d. -f1 /proc/uptime)
        
        if [ "$uptime_seconds" -gt "$age" ]; then
          # FIX: Safely flag older pages and write them down immediately
          echo "$age" > "$zr/idle" 2>/dev/null || echo all > "$zr/idle"
          echo "[zram-flush] Age mode: flushing pages untouched for $age seconds."
          echo idle > "$zr/writeback" || true
        else
          # FIX: Logical fix for early boot. Do not attempt a blank flush; mark pages idle for next loop.
          echo "[zram-flush] Early boot: marking all current pages as idle for subsequent loops."
          echo all > "$zr/idle" || true
        fi

        # 3. Defragment ZRAM storage spaces
        echo 1 > "$zr/compact" || true
      '';
    };

    # Monotonic Maintenance Timer Loop
    systemd.timers.zram-flush = lib.mkIf cfg.attachWritebackDevice {
      description = "Hourly ZRAM maintenance and writeback loop";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # FIX: Extended to 30m to ensure system settles cleanly past boot stage
        OnBootSec = "30m"; 
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "5m";
      };
    };

    # ------------------------------------------------------------
    # Systemd OOMD Policy
    # ------------------------------------------------------------
    systemd.oomd = {
      enable = true;
      enableRootSlice = false; 
      enableUserSlices = true;  
    };

    # ------------------------------------------------------------
    # Virtual Memory Tuning (Refactored)
    # ------------------------------------------------------------
    boot.kernel.sysctl = {
      # FIX: Lowered from 111 to 100 to maximize ZRAM capacity without forcing severe SSD write-amplification loops
      "vm.swappiness" = 100;            
      "vm.watermark_boost_factor" = 0;   
      "vm.watermark_scale_factor" = 125; 
      "vm.page-cluster" = 0;             
    };

    # Continuous Storage Housekeeping
    services.fstrim.enable = true;
  };
}