# tty1: Wayland-Sitzung (sway + foot) starten und darin Claude Code.
# Zurueck zum cage-Kiosk:  touch ~/.no-sway
# Nur nackte Textkonsole:  touch ~/.no-sway ~/.no-cage
# Gar kein Autostart:      touch ~/.no-autoclaude

if [ -e "$HOME/.no-autoclaude" ]; then
    :
elif [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY$DISPLAY" ] && [ -z "$AUTOCLAUDE_STAGE" ]; then
    # Stufe 1 - Textkonsole
    # cage/wlroots kennt nur XKB_DEFAULT_*; ohne die Variablen landet man auf "us".
    # Quelle bleibt localectl, damit es eine einzige Wahrheit gibt.
    if [ -r /etc/X11/xorg.conf.d/00-keyboard.conf ]; then
        eval "$(awk -F'"' '
            /XkbLayout/  {printf "XKB_DEFAULT_LAYOUT=%s\n",  $4}
            /XkbModel/   {printf "XKB_DEFAULT_MODEL=%s\n",   $4}
            /XkbVariant/ {printf "XKB_DEFAULT_VARIANT=%s\n", $4}
            /XkbOptions/ {printf "XKB_DEFAULT_OPTIONS=%s\n", $4}
        ' /etc/X11/xorg.conf.d/00-keyboard.conf)"
        export XKB_DEFAULT_LAYOUT XKB_DEFAULT_MODEL XKB_DEFAULT_VARIANT XKB_DEFAULT_OPTIONS
    fi

    printf 'Start in 3s  (Ctrl-C = nur Shell, "kde" = Plasma, "bl 30" = Helligkeit)\n'
    if sleep 3; then
        if command -v sway >/dev/null && [ ! -e "$HOME/.no-sway" ]; then
            AUTOCLAUDE_STAGE=done sway   # Stufe 2 setzt der sway-config-exec
        elif command -v cage >/dev/null && [ ! -e "$HOME/.no-cage" ]; then
            AUTOCLAUDE_STAGE=kiosk cage -s -- foot
        else
            AUTOCLAUDE_STAGE=done; export AUTOCLAUDE_STAGE
            cd "$HOME" && claude
        fi
        export AUTOCLAUDE_STAGE=done
    fi
elif [ "$AUTOCLAUDE_STAGE" = "kiosk" ]; then
    # Stufe 2 - in foot unter sway/cage
    export AUTOCLAUDE_STAGE=done
    cd "$HOME"
    # tmux: mehrere Claude-Sessions nebeneinander, ueberlebt einen Kiosk-Neustart.
    # Ctrl-b C = neues Claude-Fenster, Ctrl-b w = Fensterliste, Ctrl-b d = detach
    if command -v tmux >/dev/null && [ ! -e "$HOME/.no-tmux" ]; then
        tmux new-session -A -s main "claude; exec bash -i"
    else
        claude
    fi
fi
