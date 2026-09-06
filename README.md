# tmux-status

CPU load, network throughput and battery for the tmux status line, as a single
small C program with no dependencies beyond libc.

```
 53% ↓0.0Mbit ↑12.4Mbit 󰁹78% 1:35h 21.9W
```

* **CPU** — busy percentage over the last interval, from `/proc/stat`.
  Turns red at 70 %.
* **Network** — average throughput over the last interval in decimal Mbit/s,
  from `/proc/net/dev`. Loopback and virtual interfaces (`veth*`, `docker*`,
  `podman*`, `br-*`, …) are skipped so bridged traffic is not counted twice.
* **Battery** — charge, remaining time and current draw from
  `/sys/class/power_supply/BAT0`. Remaining time uses a weighted average of the
  last twelve power samples, so it follows load changes without jumping every
  tick. Batteries exposed through the SBS driver report `charge_*`/`current_*`
  in µAh/µA instead of `energy_*`/`power_* in µWh/µW; both are handled.

Colours are [Catppuccin Mocha](https://github.com/catppuccin/catppuccin).

## Build

```sh
make && make install      # -> ~/.local/bin/tmux-status
```

`make install` also kills any running instance: tmux keeps the old inode of a
`#()` job alive and will not respawn it just because the file on disk changed.

## Use

```tmux
set -g status-interval 5
set -g status-right-length 90
set -g status-right "#(~/.local/bin/tmux-status --loop 5) %H:%M "
```

`tmux.conf` in this repo is the full config the screenshot line comes from,
including the Catppuccin styling around it. `sway.config` is the compositor
side of the same setup — it binds the MacBook's F3 special key, which sends
`KEY_SCALE` and so never reaches the terminal at all, to `tmux-cycle-view`.

## View cycle

`tmux-cycle-view` cycles a session between three arrangements: every terminal
side by side, the same panes tiled, and one window per terminal. `--next` steps
to the next window, or to the next pane once everything is gathered. Bound to
`prefix + Space` and, through sway, to the F3 key with and without Ctrl.

Called without a window id it has no tmux context to work from, so it resolves
the session over `#{client_session}` from `list-clients`. Neither a bare
`display -p` nor `display -p -c <client>` reports the session a client is
actually looking at — both answer with the most recently used one, which is a
different session more often than it sounds.

`--loop [seconds]` is the intended mode: tmux starts a `#()` job once and reads
lines from it for as long as the process lives, which avoids a fork/exec per
tick — at roughly 1 ms that was by far the largest cost. The program exits by
itself via SIGPIPE once tmux closes the read end, and only writes a line when
the rendered output actually changed, so an idle bar causes no redraws at all.

Without `--loop` it prints one line and keeps its counters in
`$XDG_RUNTIME_DIR/.tmux-cpu`, which is useful for testing.

The battery path can be overridden at build time:

```sh
make CFLAGS='-O2 -DBATDIR=\"/sys/class/power_supply/BAT1/\"'
```

## specialkeysd

Booting into a bare sway session means nothing handles the laptop's special
keys any more — powerdevil and kglobalaccel used to. `specialkeysd` takes over:
display and keyboard brightness, dimming after an idle timeout, and the
Exposé/Dashboard keys, which drive the tmux view above. It reads `/dev/input`
directly and writes `/sys/class/backlight`, so it runs as root via
`specialkeysd.service` and drops to the desktop user to talk to tmux.

```sh
make install-daemon       # -> /usr/local/sbin, needs sudo
```

Keys must be handled in exactly one place. Binding one of them in the
compositor as well means two actions per press — the config comments in
`sway.config` record both times that happened, once for brightness and once
for Exposé.

## Notes

The glyphs (, 󰁹, 󰂄) come from a Nerd Font — the status line needs one to
render them. Source comments are in German.
