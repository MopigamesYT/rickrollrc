#!/bin/bash

# Download the Emislug image
WALLPAPER_PATH="$HOME/Pictures/emislug-wallpaper.jpg"
IMAGE_URL="https://i.imgur.com/tHL2Llq.jpeg"

# Create Pictures directory if it doesn't exist
mkdir -p "$HOME/Pictures"

# Download the image
echo "Downloading Emislug wallpaper..."
wget -O "$WALLPAPER_PATH" "$IMAGE_URL"

if [ $? -eq 0 ]; then
    echo "Image downloaded successfully to $WALLPAPER_PATH"
    
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
else
    echo "Failed to download the image. Please check your internet connection."
    exit 1
fi
