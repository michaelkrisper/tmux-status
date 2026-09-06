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
including the Catppuccin styling around it.

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

## Notes

The glyphs (, 󰁹, 󰂄) come from a Nerd Font — the status line needs one to
render them. Source comments are in German.
