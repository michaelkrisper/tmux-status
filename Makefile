CFLAGS ?= -O2 -Wall -Wextra
PREFIX ?= $(HOME)/.local

tmux-status: tmux-status.c
	$(CC) $(CFLAGS) -o $@ $<

# tmux haelt den laufenden #()-Job an der alten Inode fest und startet ihn
# nicht von selbst neu -- darum nach dem Kopieren beenden, tmux respawnt.
install: tmux-status
	install -Dm755 tmux-status $(PREFIX)/bin/tmux-status
	install -Dm755 tmux-cycle-view $(PREFIX)/bin/tmux-cycle-view
	-pkill -x tmux-status

specialkeysd: specialkeysd.c
	$(CC) $(CFLAGS) -o $@ $<

# Braucht root: der Dienst liest /dev/input und schreibt /sys/class/backlight,
# beides darf nur root. Darum getrennt von "install".
install-daemon: specialkeysd
	sudo install -Dm755 specialkeysd /usr/local/sbin/specialkeysd
	sudo install -Dm644 specialkeysd.service /etc/systemd/system/specialkeysd.service
	sudo systemctl daemon-reload
	sudo systemctl restart specialkeysd

clean:
	rm -f tmux-status specialkeysd

.PHONY: install install-daemon clean
