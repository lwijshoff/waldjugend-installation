#!/bin/bash

# WordPress waldjugend-theme Update Script
# Ensure this script is run as root or with sudo.

# Developed by Leonard Wijshoff in 2025
# https://github.com/lwijshoff
# See LICENSE for more information

# Exit on errors
set -e

# Save the directory where the script was executed from
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source the config file
source "$SCRIPT_DIR/config.sh"  # Ensure it's sourced relative to the current script's location

# Derive theme folder name from the repo URL and build the path
THEME_DIR="$TARGET_DIR/wp-content/themes/$(basename $THEME_REPO .git)"

# Ensure the theme directory exists before proceeding
if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Theme directory '$THEME_DIR' does not exist!"
    exit 1
fi

# Go to the theme directory
cd "$THEME_DIR"

# Mark the directory as a safe Git directory locally to prevent "dubious ownership" errors
if [ -d .git ]; then
    git config --global --add safe.directory "$THEME_DIR"
else
    echo "Error: '$THEME_DIR' is not a Git repository!"
    exit 1
fi

# Get latest commit hash and message
LAST_COMMIT_HASH=$(git rev-parse --short HEAD)
LAST_COMMIT_MESSAGE=$(git log -1 --pretty=%B)

# echo "Commit: $LAST_COMMIT_HASH"
# echo "Message: $LAST_COMMIT_MESSAGE"

# Fetch the latest tags and releases from GitHub
echo "Fetching tags from the remote repository..."
git fetch --tags

# Get the latest tag (release) from GitHub
LATEST_RELEASE=$(git tag -l | sort -V | tail -n 1)

# Get the current installed version (local tag)
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")

echo "Current version: $CURRENT_VERSION"
echo "Latest release: $LATEST_RELEASE"

# Check if the local version is the same as the latest release
if [ "$CURRENT_VERSION" != "$LATEST_RELEASE" ]; then
    echo "A new release is available. Updating to version $LATEST_RELEASE..."
    
    git checkout "$LATEST_RELEASE"
    git pull origin "$LATEST_RELEASE"

    VERSION="$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --abbrev-ref HEAD)"
else
    echo "You are already on the latest release ($LATEST_RELEASE). No update needed."
    exit 0
fi

# Set the proper ownership and permissions
echo "Setting ownership and permissions for the theme..."
sudo chown -R www-data:www-data "$THEME_DIR"
sudo chmod -R 775 "$THEME_DIR"

# Print success message
clear
cat "$SCRIPT_DIR/assets/ascii-waldjugend-art.txt"
printf "\nUpdated to version: %s\n" "$VERSION"
printf "Theme update complete!\n"