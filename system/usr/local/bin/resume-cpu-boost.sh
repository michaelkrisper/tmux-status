#!/usr/bin/env bash
# Kurzer CPU-Performance-Burst direkt nach dem Resume, damit die Aufwach-Arbeit
# schnell durchlaeuft. Wird via systemd-run im Hintergrund gestartet, blockiert
# den Resume also nicht. Turbo bleibt danach an (siehe cpu-power.service).
set -u
BOOST_SECONDS=4
gov() { for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "$1" > "$g" 2>/dev/null || true; done; }

gov performance
sleep "$BOOST_SECONDS"
gov powersave
