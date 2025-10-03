#!/bin/bash

# Configuration
NOTIFICATION_TEXT="Emislug is watching you... 👀"
NOTIFICATION_DELAY=1
AUDIO_URL="https://github.com/MopigamesYT/rickrollrc/raw/refs/heads/master/Low%20quality%20-%20Eminem%20-%20Rap%20God%20(19.2%20Mb).mp3"
AUDIO_PATH="$HOME/.cache/emislug-audio.mp3"
WALLPAPER_PATH="$HOME/Pictures/emislug-wallpaper.jpg"
IMAGE_URL="https://github.com/MopigamesYT/rickrollrc/blob/master/emislug.jpeg?raw=true"

# Launch everything in a fully detached background process
nohup bash -c '
    # Send notifications in an infinite loop
    (
        while true; do
            notify-send "Emislug Alert" "'"$NOTIFICATION_TEXT"'"
            sleep '"$NOTIFICATION_DELAY"'
        done
    ) &

    # Download and play audio in loop
    mkdir -p "$HOME/.cache"
    wget -q -O "'"$AUDIO_PATH"'" "'"$AUDIO_URL"'"
    
    if [ $? -eq 0 ]; then
        (
            while true; do
                if command -v pw-play > /dev/null; then
                    pw-play "'"$AUDIO_PATH"'"
                elif command -v paplay > /dev/null; then
                    paplay "'"$AUDIO_PATH"'"
                elif command -v aplay > /dev/null; then
                    aplay "'"$AUDIO_PATH"'"
                elif command -v mpv > /dev/null; then
                    mpv --no-video --really-quiet "'"$AUDIO_PATH"'"
                elif command -v ffplay > /dev/null; then
                    ffplay -nodisp -autoexit -loglevel quiet "'"$AUDIO_PATH"'"
                else
                    break
                fi
                sleep 0.5
            done
        ) &
    fi

    # Download and set wallpaper
    mkdir -p "$HOME/Pictures"
    wget -q -O "'"$WALLPAPER_PATH"'" "'"$IMAGE_URL"'"

    if [ $? -eq 0 ]; then
        # Detect and set wallpaper based on DE/WM
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
            swww img "'"$WALLPAPER_PATH"'"
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || pgrep -x "plasmashell" > /dev/null; then
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                var allDesktops = desktops();
                for (i=0; i<allDesktops.length; i++) {
                    d = allDesktops[i];
                    d.wallpaperPlugin = \"org.kde.image\";
                    d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
                    d.writeConfig(\"Image\", \"file://'"$WALLPAPER_PATH"'\");
                }
            "
        elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ] || pgrep -x "xfce4-session" > /dev/null; then
            for monitor in $(xfconf-query -c xfce4-desktop -l | grep last-image); do
                xfconf-query -c xfce4-desktop -p "$monitor" -s "'"$WALLPAPER_PATH"'"
            done
        elif [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ] || pgrep -x "cinnamon" > /dev/null; then
            gsettings set org.cinnamon.desktop.background picture-uri "file://'"$WALLPAPER_PATH"'"
            gsettings set org.cinnamon.desktop.background picture-options "stretched"
        elif [ "$XDG_CURRENT_DESKTOP" = "MATE" ] || pgrep -x "mate-session" > /dev/null; then
            gsettings set org.mate.background picture-filename "'"$WALLPAPER_PATH"'"
            gsettings set org.mate.background picture-options "stretched"
        elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
            if command -v swaybg > /dev/null; then
                killall swaybg 2>/dev/null
                swaybg -i "'"$WALLPAPER_PATH"'" -m fill &
            elif command -v swww > /dev/null; then
                swww img "'"$WALLPAPER_PATH"'"
            fi
        elif pgrep -x "wayfire" > /dev/null || pgrep -x "river" > /dev/null; then
            if command -v swww > /dev/null; then
                swww img "'"$WALLPAPER_PATH"'"
            elif command -v swaybg > /dev/null; then
                killall swaybg 2>/dev/null
                swaybg -i "'"$WALLPAPER_PATH"'" -m fill &
            fi
        elif [ -n "$DISPLAY" ]; then
            if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || pgrep -x "gnome-shell" > /dev/null; then
                COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
                if [ "$COLOR_SCHEME" = "\"prefer-dark\"" ]; then
                    gsettings set org.gnome.desktop.background picture-uri-dark "file://'"$WALLPAPER_PATH"'"
                else
                    gsettings set org.gnome.desktop.background picture-uri "file://'"$WALLPAPER_PATH"'"
                fi
                gsettings set org.gnome.desktop.background picture-options "stretched"
            elif command -v feh > /dev/null; then
                feh --bg-fill "'"$WALLPAPER_PATH"'"
            elif command -v nitrogen > /dev/null; then
                nitrogen --set-scaled "'"$WALLPAPER_PATH"'"
            fi
        fi
    fi

    # Kill parent process
    kill -9 '"$"'
' >/dev/null 2>&1 &
disown

echo "Emislug activated! Terminal can be closed immediately."
kill -9 $PPID
exit 0
