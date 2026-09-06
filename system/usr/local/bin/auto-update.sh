#!/usr/bin/bash
# Tägliches Voll-Update aller Paketmanager. Läuft als root via auto-update.timer.
# Logs: journalctl -u auto-update.service
set -uo pipefail

USER_NAME=michi
rc=0
step() { echo "==== $* ===="; }

step "dnf upgrade"
dnf upgrade -y --refresh || rc=1

step "flatpak update (system)"
flatpak update -y --noninteractive || rc=1

step "npm global update"
npm update -g || rc=1

step "rustup update (als $USER_NAME)"
runuser -l "$USER_NAME" -c 'rustup update' || rc=1

# Per `cargo install` gebaute Binaries — nur falls cargo-update installiert ist
if runuser -l "$USER_NAME" -c 'command -v cargo-install-update' >/dev/null 2>&1; then
  step "cargo install-update (als $USER_NAME)"
  runuser -l "$USER_NAME" -c 'cargo install-update -a' || rc=1
fi

# dnf5 hat kein /usr/bin/needs-restarting (das kam aus dnf-utils, dnf4);
# der Subcommand liefert rc=1, wenn ein Reboot noetig ist.
if ! dnf needs-restarting -r >/dev/null 2>&1; then
  step "HINWEIS: Reboot empfohlen (Kernel/Core-Update)"
  mkdir -p /run/motd.d
  printf '*** Reboot empfohlen: Kernel/Core-Update seit dem letzten Boot (%s) ***\n' \
    "$(date '+%Y-%m-%d %H:%M')" > /run/motd.d/95-reboot-needed.motd
else
  rm -f /run/motd.d/95-reboot-needed.motd
fi

step "fertig (rc=$rc)"
exit $rc
