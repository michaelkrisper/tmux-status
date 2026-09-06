CFLAGS ?= -O2 -Wall -Wextra
PREFIX ?= $(HOME)/.local

tmux-status: tmux-status.c
	$(CC) $(CFLAGS) -o $@ $<

# tmux haelt den laufenden #()-Job an der alten Inode fest und startet ihn
# nicht von selbst neu -- darum nach dem Kopieren beenden, tmux respawnt.
install: tmux-status
	install -Dm755 tmux-status $(PREFIX)/bin/tmux-status
	-pkill -x tmux-status

clean:
	rm -f tmux-status

.PHONY: install clean
