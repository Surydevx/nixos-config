{ pkgs, lib, ... }:

{
  # ------------------------------------------------------------------
  # Zen kernel base
  # ------------------------------------------------------------------
  # Zen already provides excellent desktop responsiveness.
  # We are only adding targeted config and boot parameters.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # ------------------------------------------------------------------
  # Custom kernel config
  # ------------------------------------------------------------------
  # Note:
  # Using boot.kernelPatches with extraConfig forces a custom kernel build.
  # This is expected since you are willing to wait for compilation.
  boot.kernelPatches = [
    {
      name = "i5-8th-gen-u-dev-optimized";
      patch = null;

      extraConfig = ''
        # ------------------------------------------------------------
        # Debug/verification convenience
        # ------------------------------------------------------------
        # Allows checking the final kernel config via /proc/config.gz
        IKCONFIG y
        IKCONFIG_PROC y

        # ------------------------------------------------------------
        # CPU topology optimization for i5 8th Gen U-series
        # ------------------------------------------------------------
        # Your CPU has 4 cores / 8 threads.
        # Reducing NR_CPUS from generic large values reduces scheduler
        # data structure overhead slightly.
        NR_CPUS 8

        # Scheduler topology awareness
        SCHED_MC y
        SCHED_SMT y
        SCHED_AUTOGROUP y

        # ------------------------------------------------------------
        # Responsiveness and idle power
        # ------------------------------------------------------------
        # 1000 Hz is good for desktop responsiveness.
        # If battery life becomes more important than responsiveness,
        # HZ_500 can be used instead.
        HZ_1000 y
        HZ 1000

        # Tickless idle is important for laptop power savings.
        NO_HZ_IDLE y

        # Do not use full tickless mode.
        # It can increase latency/power overhead for desktop/laptop use.
        NO_HZ_FULL n

        # Dynamic preemption is a good balance for desktop/dev work.
        PREEMPT_DYNAMIC y

        # ------------------------------------------------------------
        # Intel power management / thermal drivers
        # ------------------------------------------------------------
        # Required for proper intel_pstate behavior.
        X86_INTEL_PSTATE y

        # Useful governor support.
        CPU_FREQ_GOV_SCHEDUTIL y

        # CPU idle support.
        CPU_IDLE y
        CPU_IDLE_GOV_MENU y
        INTEL_IDLE y

        # Thermal/power monitoring used by thermald/TLP/sysfs tooling.
        POWERCAP y
        INTEL_RAPL y
        X86_PKG_TEMP_THERMAL y

        # ------------------------------------------------------------
        # RAM management synergy
        # ------------------------------------------------------------
        # Required for zram-based swap.
        SWAP y

        # We are using zram, not zswap.
        # Avoid stacking two compressed swap layers.
        ZSWAP n

        # ZRAM core and allocator support.
        ZRAM y
        ZSMALLOC y
        ZPOOL y

        # Required by your zram-flush writeback logic.
        ZRAM_WRITEBACK y

        # Required for idle page tracking in your zram-flush service.
        ZRAM_MEMORY_TRACKING y

        # zstd compression support for zram.
        CRYPTO_ZSTD y
        ZSTD_COMPRESS y
        ZSTD_DECOMPRESS y

        # Required for systemd-oomd and PSI-based memory pressure.
        PSI y

        # Cgroup memory controller.
        MEMCG y

        # Useful for cgroup-aware writeback behavior.
        BLK_CGROUP y
        CGROUP_WRITEBACK y

        # Transparent hugepages in madvise mode.
        # Your boot parameters already set transparent_hugepage=madvise.
        TRANSPARENT_HUGEPAGE y
        TRANSPARENT_HUGEPAGE_MADVISE y

        # ------------------------------------------------------------
        # Networking
        # ------------------------------------------------------------
        # BBR congestion control.
        TCP_CONG_BBR y
        DEFAULT_BBR y

        # BBR works best with fq qdisc.
        NET_SCH_FQ y

        # ------------------------------------------------------------
        # Developer tooling support
        # ------------------------------------------------------------
        # Keep profiling available for perf and development work.
        PROFILING y

        # BPF support for modern tracing/tooling.
        BPF_SYSCALL y
        BPF_JIT y

        # ------------------------------------------------------------
        # Optional filesystem support
        # ------------------------------------------------------------
        # If your root/home are Btrfs and you use compress=zstd,
        # uncomment these to make sure Btrfs zstd support is built in.
        #
        # BTRFS_FS y
        # BTRFS_FS_ZSTD y

        # ------------------------------------------------------------
        # Optional i915 GuC/HuC config exposure
        # ------------------------------------------------------------
        # Usually not needed on Zen because distro/Zen config usually
        # exposes enough i915 firmware support.
        #
        # Only uncomment these if dmesg shows GuC/HuC unsupported or
        # i915.enable_guc is ignored.
        #
        # EXPERT y
        # DRM_I915_GUC y
        # DRM_I915_HUC y
      '';
    }
  ];

  # ------------------------------------------------------------------
  # Kernel boot parameters
  # ------------------------------------------------------------------
  boot.kernelParams = [
    # ----------------------------------------------------------------
    # CPU/power baseline
    # ----------------------------------------------------------------
    # Use Intel's native P-state driver.
    # Works well with auto-cpufreq and thermald.
    "intel_pstate=active"

    # Disable split-lock mitigation penalty.
    # Useful for some userspace/container/workload performance.
    # Security trade-off is usually acceptable on a personal dev machine.
    "split_lock_mitigate=0"

    # Disable watchdog timers for a small latency/power overhead reduction.
    "nowatchdog"

    # ----------------------------------------------------------------
    # Intel UHD 620 / i915 tuning
    # ----------------------------------------------------------------
    # 3 = GuC submission + HuC.
    #
    # If you experience GPU hangs, screen flicker, suspend issues,
    # or i915 firmware errors, change this to:
    #
    #   i915.enable_guc=2
    #
    # For stability-first UHD 620 usage, 2 is often enough because it
    # enables HuC without forcing GuC submission.
    "i915.enable_guc=3"

    # Panel Self Refresh.
    # Can improve laptop battery life.
    # If you see screen flickering or display artifacts, remove this.
    "i915.enable_psr=1"

    # Faster display initialization during boot.
    "i915.fastboot=1"

    # ----------------------------------------------------------------
    # Optional parameters
    # ----------------------------------------------------------------
    # Disable CPU side-channel mitigations.
    # Noticeable performance boost on older CPUs, but security risk.
    #
    # Only enable if you understand the trade-off and do not run
    # untrusted code/containers/browser workloads without sandboxing.
    #
    # "mitigations=off"

    # Ignore BIOS performance limits.
    # Can increase heat on 15W U-series laptops.
    # Not recommended unless you know your BIOS is artificially limiting
    # performance in a harmful way.
    #
    # "processor.ignore_ppc=1"

    # If you have an NVMe SSD and notice wake-up latency or micro-stutter
    # after idle, you can test this. It reduces NVMe deep sleep.
    #
    # Battery life may decrease.
    #
    # "nvme_core.default_ps_max_latency_us=0"
  ];

  # ------------------------------------------------------------------
  # Runtime sysctls
  # ------------------------------------------------------------------
  # Keep memory pressure/swappiness/watermark tuning in ram-management.nix.
  # Here we only add kernel/workload-related sysctls.
  boot.kernel.sysctl = {
    # Needed for heavy development workloads:
    # Docker, Elasticsearch, Android tooling, some IDEs, large projects.
    "vm.max_map_count" = 2147483642;

    # Needed for many development/file-watch workloads:
    # VS Code, JetBrains, Node.js, Webpack, Vite, Cargo, Rust Analyzer.
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;

    # BBR works best with fq.
    "net.core.default_qdisc" = "fq";

    # Make sure BBR is active at runtime as well.
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # ------------------------------------------------------------------
  # Firmware
  # ------------------------------------------------------------------
  # Intel GPU/Wi-Fi/Bluetooth firmware is usually already handled,
  # but this can help if firmware loading is missing.
  #
  # hardware.enableRedistributableFirmware = true;
}