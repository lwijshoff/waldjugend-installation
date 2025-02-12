#!/bin/bash

# WordPress waldjugend-theme Update Script
# Ensure this script is run as root or with sudo.

# Developed by Leonard Wijshoff in 2025
# https://github.com/lwijshoff
# See LICENSE for more information

# Exit on errors
set -e

# Enable debug mode if you wish to pull changes from dev instead 
DEBUG=false

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

# If debug mode is enabled, switch to dev branch instead of checking tags
if [ "$DEBUG" = true ]; then
    echo "Debug mode enabled: Pulling latest changes from 'dev' branch..."

    git checkout dev
    git pull origin dev

    # Get latest commit hash and message
    LAST_COMMIT_HASH=$(git rev-parse --short HEAD)
    LAST_COMMIT_MESSAGE=$(git log -1 --pretty=%B)

    echo "Latest commit pulled:"
    echo "Commit: $LAST_COMMIT_HASH"
    echo "Message: $LAST_COMMIT_MESSAGE"

    VERSION="dev #$LAST_COMMIT_HASH"

else # Else is equal to debug=false
    # Fetch the latest tags and releases from GitHub
    echo "Fetching tags from the remote repository..."
    git fetch --tags

    # Get the latest tag (release) from GitHub
    LATEST_RELEASE=$(git tag -l | sort -V | tail -n 1)

    # Get the current installed version (local tag)
    CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")

    # Get the current branch name
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo "Current version: $CURRENT_VERSION"
    echo "Latest release: $LATEST_RELEASE"
    # echo "Current branch: $CURRENT_BRANCH"

    # Check if the local version is the same as the latest release
    if [ "$CURRENT_VERSION" != "$LATEST_RELEASE" ]; then
        echo "A new release is available. Updating to version $LATEST_RELEASE..."
        
        git checkout "$LATEST_RELEASE"
        git pull origin "$LATEST_RELEASE"

        VERSION="$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --abbrev-ref HEAD)"
    else if [ "$CURRENT_BRANCH" = "dev" ]; then
        echo "You are still on 'dev'. Degrading to the latest release ($LATEST_RELEASE)"

        git stash
        git checkout "$LATEST_RELEASE"
        git pull origin "$LATEST_RELEASE"

        VERSION="$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --abbrev-ref HEAD)"
    else
        echo "You are already on the latest release ($LATEST_RELEASE). No update needed."
        exit 0
    fi
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