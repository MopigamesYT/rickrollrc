#!/bin/bash

# Configuration
NOTIFICATION_TEXT="Emislug is watching you... 👀"
NOTIFICATION_DELAY=1
AUDIO_URL="https://github.com/MopigamesYT/rickrollrc/raw/refs/heads/master/Low%20quality%20-%20Eminem%20-%20Rap%20God%20(19.2%20Mb).mp3"
AUDIO_PATH="$HOME/.cache/emislug-audio.mp3"
WALLPAPER_PATH="$HOME/Pictures/emislug-wallpaper.jpg"
IMAGE_URL="https://github.com/MopigamesYT/rickrollrc/blob/master/emislug.jpeg?raw=true"

# Function to detect if GNOME is using a dark theme
detect_gnome_dark_theme() {
    # Method 1: Check color-scheme (GNOME 42+)
    local color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    if [ "$color_scheme" = "'prefer-dark'" ]; then
        return 0
    fi
    
    # Method 2: Check GTK theme name for dark indicators
    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'\"")
    if [[ "$gtk_theme" =~ [Dd]ark ]] || [[ "$gtk_theme" =~ [Nn]ight ]]; then
        return 0
    fi
    
    # Method 3: Check if dark mode is enabled via legacy setting
    local dark_enabled=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
    if [[ "$dark_enabled" =~ Adwaita-dark ]]; then
        return 0
    fi
    
    # Default to light theme
    return 1
}

# Launch everything in a fully detached background process
(
    # Send notifications in an infinite loop
    (
        while true; do
            notify-send "Emislug Alert" "$NOTIFICATION_TEXT"
            sleep "$NOTIFICATION_DELAY"
        done
    ) &

    # Download and play audio in loop
    mkdir -p "$HOME/.cache"
    wget -q -O "$AUDIO_PATH" "$AUDIO_URL"
    
    if [ $? -eq 0 ]; then
        (
            while true; do
                if command -v pw-play > /dev/null; then
                    pw-play "$AUDIO_PATH"
                elif command -v paplay > /dev/null; then
                    paplay "$AUDIO_PATH"
                elif command -v aplay > /dev/null; then
                    aplay "$AUDIO_PATH"
                elif command -v mpv > /dev/null; then
                    mpv --no-video --really-quiet "$AUDIO_PATH"
                elif command -v ffplay > /dev/null; then
                    ffplay -nodisp -autoexit -loglevel quiet "$AUDIO_PATH"
                else
                    break
                fi
                sleep 0.5
            done
        ) &
    fi

    # Create floating Emislug window that moves around using Python (preinstalled)
    (
        # Download image for floating window
        FLOAT_IMAGE="$HOME/.cache/emislug-float.jpg"
        wget -q -O "$FLOAT_IMAGE" "$IMAGE_URL"
        
        if [ $? -eq 0 ] && command -v python3 > /dev/null; then
            python3 - "$FLOAT_IMAGE" << 'PYTHON_SCRIPT'
import tkinter as tk
from PIL import Image, ImageTk
import sys
import random

# Get image path from argument
image_path = sys.argv[1]

# Create window
root = tk.Tk()
root.title("Emislug")
root.attributes('-topmost', True)
root.overrideredirect(True)  # Remove window decorations

# Get screen dimensions
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()

# Window size
win_size = 200

# Load and resize image
try:
    img = Image.open(image_path)
    img = img.resize((win_size, win_size), Image.Resampling.LANCZOS)
    photo = ImageTk.PhotoImage(img)
    
    label = tk.Label(root, image=photo, bd=0)
    label.pack()
except:
    # Fallback if image loading fails
    label = tk.Label(root, text="👀", font=("Arial", 100), bd=0)
    label.pack()

# Initial position and velocity
x = random.randint(0, screen_width - win_size)
y = random.randint(0, screen_height - win_size)
vx = random.randint(3, 8)
vy = random.randint(3, 8)

def move_window():
    global x, y, vx, vy
    
    # Update position
    x += vx
    y += vy
    
    # Bounce off edges
    if x <= 0 or x >= screen_width - win_size:
        vx = -vx
    if y <= 0 or y >= screen_height - win_size:
        vy = -vy
    
    # Move window
    root.geometry(f"{win_size}x{win_size}+{x}+{y}")
    
    # Schedule next move
    root.after(50, move_window)

# Start moving
move_window()

# Run
root.mainloop()
PYTHON_SCRIPT
        fi
    ) &

    # Download and set wallpaper
    mkdir -p "$HOME/Pictures"
    wget -q -O "$WALLPAPER_PATH" "$IMAGE_URL"

    if [ $? -eq 0 ]; then
        # Detect and set wallpaper based on DE/WM
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
            swww img "$WALLPAPER_PATH"
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || pgrep -x "plasmashell" > /dev/null; then
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                var allDesktops = desktops();
                for (i=0; i<allDesktops.length; i++) {
                    d = allDesktops[i];
                    d.wallpaperPlugin = \"org.kde.image\";
                    d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
                    d.writeConfig(\"Image\", \"file://$WALLPAPER_PATH\");
                }
            "
        elif [ "$XDG_CURRENT_DESKTOP" = "XFCE" ] || pgrep -x "xfce4-session" > /dev/null; then
            for monitor in $(xfconf-query -c xfce4-desktop -l | grep last-image); do
                xfconf-query -c xfce4-desktop -p "$monitor" -s "$WALLPAPER_PATH"
            done
        elif [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ] || pgrep -x "cinnamon" > /dev/null; then
            gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER_PATH"
            gsettings set org.cinnamon.desktop.background picture-options "stretched"
        elif [ "$XDG_CURRENT_DESKTOP" = "MATE" ] || pgrep -x "mate-session" > /dev/null; then
            gsettings set org.mate.background picture-filename "$WALLPAPER_PATH"
            gsettings set org.mate.background picture-options "stretched"
        elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || pgrep -x "sway" > /dev/null; then
            if command -v swaybg > /dev/null; then
                killall swaybg 2>/dev/null
                swaybg -i "$WALLPAPER_PATH" -m fill &
            elif command -v swww > /dev/null; then
                swww img "$WALLPAPER_PATH"
            fi
        elif pgrep -x "wayfire" > /dev/null || pgrep -x "river" > /dev/null; then
            if command -v swww > /dev/null; then
                swww img "$WALLPAPER_PATH"
            elif command -v swaybg > /dev/null; then
                killall swaybg 2>/dev/null
                swaybg -i "$WALLPAPER_PATH" -m fill &
            fi
        elif [ -n "$DISPLAY" ]; then
            if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || pgrep -x "gnome-shell" > /dev/null; then
                # Enhanced GNOME dark theme detection
                if detect_gnome_dark_theme; then
                    # Set dark wallpaper
                    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
                    # Also set light in case detection is wrong
                    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
                else
                    # Set light wallpaper
                    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
                    # Also set dark in case detection is wrong
                    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
                fi
                gsettings set org.gnome.desktop.background picture-options "stretched"
            elif command -v feh > /dev/null; then
                feh --bg-fill "$WALLPAPER_PATH"
            elif command -v nitrogen > /dev/null; then
                nitrogen --set-scaled "$WALLPAPER_PATH"
            fi
        fi
    fi
) </dev/null >/dev/null 2>&1 &
disown

# Give the background process time to fully detach
sleep 0.5

echo "Emislug activated! Terminal can be closed immediately."
