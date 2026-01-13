#!/bin/bash
set -e

echo "Downloading Hytale Server files..."

# Create downloads directory
mkdir -p /downloads

# Download hytale-downloader if not present
if [ ! -f /downloads/hytale-downloader ]; then
  echo "Downloading hytale-downloader CLI..."
  cd /downloads

  wget -q https://downloader.hytale.com/hytale-downloader.zip -O hytale-downloader.zip
  unzip -q hytale-downloader.zip
  chmod +x hytale-downloader
  rm hytale-downloader.zip

  echo "hytale-downloader downloaded successfully."
fi

cd /downloads

# Determine version to download
VERSION_ARG=""
if [ "$HYTALE_VERSION" != "latest" ]; then
  VERSION_ARG="-patchline ${HYTALE_VERSION}"
fi

# Download the game files
echo "Downloading Hytale ${HYTALE_VERSION}..."
if [ -n "$VERSION_ARG" ]; then
  ./hytale-downloader ${VERSION_ARG} -download-path game.zip
else
  ./hytale-downloader -download-path game.zip
fi

# Extract to temporary location
echo "Extracting game files..."
unzip -q game.zip -d /tmp/hytale-extract

# Copy server files to /data
echo "Installing server files..."
if [ -d /tmp/hytale-extract/Server ]; then
  cp -r /tmp/hytale-extract/Server/* /data/
fi

if [ -f /tmp/hytale-extract/Assets.zip ]; then
  cp /tmp/hytale-extract/Assets.zip /data/
fi

# Copy AOT cache if available
if [ -f /tmp/hytale-extract/HytaleServer.aot ]; then
  cp /tmp/hytale-extract/HytaleServer.aot /data/
fi

# Cleanup
rm -rf /tmp/hytale-extract
rm -f game.zip

# Verify installation
if [ ! -f /data/HytaleServer.jar ]; then
  echo "ERROR: HytaleServer.jar not found after download!"
  exit 1
fi

if [ ! -f /data/Assets.zip ]; then
  echo "ERROR: Assets.zip not found after download!"
  exit 1
fi

# Fix ownership of downloaded files
chown -R hytale:hytale /data 2>/dev/null || true

echo "Hytale Server files downloaded successfully!"
echo "Version: $(java -jar /data/HytaleServer.jar --version 2>&1 || echo 'unknown')"
