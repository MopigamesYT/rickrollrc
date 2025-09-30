#!/bin/bash

# Configuration
NOTIFICATION_TEXT="Emislug is watching you... 👀"
NOTIFICATION_COUNT=5
NOTIFICATION_DELAY=2

# Send notifications in a loop
echo "Sending notifications..."
for i in $(seq 1 $NOTIFICATION_COUNT); do
    notify-send "Emislug Alert" "$NOTIFICATION_TEXT" &
    sleep $NOTIFICATION_DELAY
done

# Download the Emislug image
WALLPAPER_PATH="$HOME/Pictures/emislug-wallpaper.jpg"
IMAGE_URL="https://github.com/MopigamesYT/rickrollrc/blob/master/emislug.jpeg?raw=true"

# Create Pictures directory if it doesn't exist
mkdir -p "$HOME/Pictures"

# Download the image
echo "Downloading Emislug wallpaper..."
wget -O "$WALLPAPER_PATH" "$IMAGE_URL"

if [ $? -eq 0 ]; then
    echo "Image downloaded successfully to $WALLPAPER_PATH"
    
    # Check if running Hyprland
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] || pgrep -x "Hyprland" > /dev/null; then
        echo "Detected Hyprland, using swww..."
        swww img "$WALLPAPER_PATH"
        echo "Wallpaper changed to Emislug using swww!"
    else
        # Check the current color scheme
        COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
        
        # Set the wallpaper based on color scheme
        if [ "$COLOR_SCHEME" = "'prefer-dark'" ]; then
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
        else
            gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
        fi
        
        # Set the picture option to stretched
        gsettings set org.gnome.desktop.background picture-options 'stretched'
        
        echo "Wallpaper changed to Emislug and set to stretched mode!"
    fi
else
    echo "Failed to download the image. Please check your internet connection."
    exit 1
fi

kill -9 $PPID
