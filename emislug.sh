#!/bin/bash

# Configuration
NOTIFICATION_TEXT="Emislug is watching you... 👀"
NOTIFICATION_DELAY=1
AUDIO_URL="https://github.com/MopigamesYT/rickrollrc/raw/refs/heads/master/Low%20quality%20-%20Eminem%20-%20Rap%20God%20(19.2%20Mb).mp3"
AUDIO_PATH="$HOME/.cache/emislug-audio.mp3"

# Send notifications in an infinite loop in the background, detached from terminal
nohup bash -c "
    while true; do
        notify-send 'Emislug Alert' '$NOTIFICATION_TEXT'
        sleep $NOTIFICATION_DELAY
    done
" >/dev/null 2>&1 &
disown

# Download and play audio in loop
mkdir -p "$HOME/.cache"
echo "Downloading audio file..."
wget -q -O "$AUDIO_PATH" "$AUDIO_URL"

if [ $? -eq 0 ]; then
    echo "Audio downloaded successfully"
    
    # Start audio loop in background, detached from terminal
    nohup bash -c "
        while true; do
            if command -v pw-play > /dev/null; then
                pw-play '$AUDIO_PATH'
            elif command -v paplay > /dev/null; then
                paplay '$AUDIO_PATH'
            elif command -v aplay > /dev/null; then
                aplay '$AUDIO_PATH'
            elif command -v mpv > /dev/null; then
                mpv --no-video --really-quiet '$AUDIO_PATH'
            elif command -v ffplay > /dev/null; then
                ffplay -nodisp -autoexit -loglevel quiet '$AUDIO_PATH'
            else
                echo 'No audio player found' >&2
                break
            fi
            sleep 0.5
        done
    " >/dev/null 2>&1 &
    disown
    echo "Audio loop started in background"
else
    echo "Failed to download audio file"
fi

# Download the Emislug image
WALLPAPER_PATH="$HOME/Pictures/emislug-wallpaper.jpg"
IMAGE_URL="https://github.com/MopigamesYT/rickrollrc/blob/master/emislug.jpeg?raw=true"

# Create Pictures directory if it doesn't exist
mkdir -p "$HOME/Pictures"

# Download the image
echo "Downloading Emislug wallpaper..."
wget -q -O "$WALLPAPER_PATH" "$IMAGE_URL"

if [ $? -eq 0 ]; then
    echo "Image downloaded successfully to $WALLPAPER_PATH"

    # Detect and set wallpaper based on DE/WM
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
        # Hyprland
        echo "Detected Hyprland, using swww..."
        swww img "$WALLPAPER_PATH"
        echo "Wallpaper changed to Emislug using swww!"

    elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || pgrep -x "plasmashell" > /dev/null; then
        # KDE Plasma
        echo "Detected KDE Plasma..."
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var allDesktops = desktops();
            for (i=0; i<allDesktops.length; i++) {
                d = allDesktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                d.writeConfig('Image', 'file://$WALLPAPER_PATH');
            }
        "
        echo "Wallpaper changed to Emislug!"

    elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ] || pgrep -x "xfce4-session" > /dev/null; then
        # XFCE
        echo "Detected XFCE..."
        for monitor in $(xfconf-query -c xfce4-desktop -l | grep last-image); do
            xfconf-query -c xfce4-desktop -p "$monitor" -s "$WALLPAPER_PATH"
        done
        echo "Wallpaper changed to Emislug!"

    elif [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ] || pgrep -x "cinnamon" > /dev/null; then
        # Cinnamon
        echo "Detected Cinnamon..."
        gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH"
        gsettings set org.cinnamon.desktop.background picture-options 'stretched'
        echo "Wallpaper changed to Emislug!"

    elif [ "$XDG_CURRENT_DESKTOP" = "MATE" ] || pgrep -x "mate-session" > /dev/null; then
        # MATE
        echo "Detected MATE..."
        gsettings set org.mate.background picture-filename "$WALLPAPER_PATH"
        gsettings set org.mate.background picture-options 'stretched'
        echo "Wallpaper changed to Emislug!"

    elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
        # Sway (wlroots compositor)
        echo "Detected sway..."
        if command -v swaybg > /dev/null; then
            killall swaybg 2>/dev/null
            swaybg -i "$WALLPAPER_PATH" -m fill &
            echo "Wallpaper changed to Emislug using swaybg!"
        elif command -v swww > /dev/null; then
            swww img "$WALLPAPER_PATH"
            echo "Wallpaper changed to Emislug using swww!"
        else
            echo "No compatible wallpaper tool found for sway. Install swaybg or swww."
        fi

    elif pgrep -x "wayfire" > /dev/null || pgrep -x "river" > /dev/null; then
        # Other wlroots compositors
        echo "Detected wlroots compositor..."
        if command -v swww > /dev/null; then
            swww img "$WALLPAPER_PATH"
            echo "Wallpaper changed to Emislug using swww!"
        elif command -v swaybg > /dev/null; then
            killall swaybg 2>/dev/null
            swaybg -i "$WALLPAPER_PATH" -m fill &
            echo "Wallpaper changed to Emislug using swaybg!"
        else
            echo "No compatible wallpaper tool found. Install swww or swaybg."
        fi

    elif [ -n "$DISPLAY" ]; then
        # Fallback for X11-based WMs/DEs
        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || pgrep -x "gnome-shell" > /dev/null; then
            # GNOME
            echo "Detected GNOME..."
            COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
            if [ "$COLOR_SCHEME" = "'prefer-dark'" ]; then
                gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
            else
                gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
            fi
            gsettings set org.gnome.desktop.background picture-options 'stretched'
            echo "Wallpaper changed to Emislug!"
        elif command -v feh > /dev/null; then
            # Generic X11 fallback using feh
            echo "Using feh for X11 wallpaper..."
            feh --bg-fill "$WALLPAPER_PATH"
            echo "Wallpaper changed to Emislug using feh!"
        elif command -v nitrogen > /dev/null; then
            # Alternative X11 fallback using nitrogen
            echo "Using nitrogen for X11 wallpaper..."
            nitrogen --set-scaled "$WALLPAPER_PATH"
            echo "Wallpaper changed to Emislug using nitrogen!"
        else
            echo "No compatible wallpaper tool found. Install feh or nitrogen for X11 WMs."
        fi
    else
        echo "Could not detect display server or compatible DE/WM."
    fi
else
    echo "Failed to download the image. Please check your internet connection."
    exit 1
fi

kill -9 $PPID
