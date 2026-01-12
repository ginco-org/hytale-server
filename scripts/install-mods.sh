#!/bin/bash
set -e

echo "Checking for mods installation..."

# Create mods directory if it doesn't exist
mkdir -p /data/mods

# Check if any .jar or .zip files in /mods directory
if [ -d /mods ] && [ "$(ls -A /mods 2>/dev/null)" ]; then
  echo "Installing mods from /mods directory..."
  cp -v /mods/*.jar /data/mods/ 2>/dev/null || true
  cp -v /mods/*.zip /data/mods/ 2>/dev/null || true
  echo "Mods installed."
else
  echo "No mods to install."
fi

# Support for MODRINTH_PROJECTS and CURSEFORGE_PROJECTS in the future
# This would download mods automatically from mod repositories
