#!/usr/bin/env bash
# Entfernt ungenutzte PCI-Geraete. Fehlt eines, ist das kein Fehler.
#
# 02:00.0 ist die FaceTime-Kamera. Sie steht hier nicht nur wegen des
# Ruhestroms: \_PTS wartet mit acpi_osi=!Darwin bis zu 5000 x 1 ms darauf, dass
# \_SB.PCI0.RP02.CMRA.DPST den Wert 3 meldet. Ist die Kamera entfernt und
# Root-Port 00:1c.1 damit leer und runtime-suspended, liefert der
# ACPI-Config-Read 0xFF -- untere 2 Bit = 3, die Schleife bricht sofort ab.
# Sie vor dem Suspend per setpci nach D3 zu schreiben reicht NICHT: der
# PCI-Kern legt in dpm_suspend_noirq auch den Root-Port schlafen, und das
# passiert vor \_PTS (gemessen 2026-08-31: weiterhin 9,6 s).
set -u
for d in 0000:05:00.0 0000:00:03.0 0000:00:1b.0 0000:02:00.0; do
    f="/sys/bus/pci/devices/$d/remove"
    if [ -e "$f" ]; then
        echo 1 > "$f" && logger "pci-remove-unused: $d entfernt"
    fi
done
