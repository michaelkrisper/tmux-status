#!/usr/bin/env bash
# Setzt power_save erst, nachdem die WLAN-Verbindung wieder steht. Direkt beim
# Resume gesetzt kostet es rund 1 s, weil es in die Phase faellt, in der der
# wl-Treiber scannt und assoziiert (gemessen 2026-08-31: 9.57 s vs 8.39 s).
set -u
IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1)
[ -z "$IFACE" ] && exit 0

for _ in $(seq 1 60); do
    state=$(cat "/sys/class/net/$IFACE/operstate" 2>/dev/null)
    if [ "$state" = "up" ] && iw dev "$IFACE" link 2>/dev/null | grep -q '^Connected'; then
        iw dev "$IFACE" set power_save on
        logger "wlan-powersave: power_save on $IFACE (nach Connect)"
        exit 0
    fi
    sleep 0.5
done
iw dev "$IFACE" set power_save on
logger "wlan-powersave: power_save on $IFACE (Timeout, ohne Connect)"
