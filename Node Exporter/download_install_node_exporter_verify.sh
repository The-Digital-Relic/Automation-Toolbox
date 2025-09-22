#!/bin/bash
# =============================================================================
# Script: Install Prometheus Node Exporter
#
# Creator: The Digital Relic (TDR)
# Date: 2025-09-21
# Copyright (c) 2025 The Digital Relic (TDR)
#
# Usage:
#   ./download_install_node_exporter_verify.sh [VERSION]
#   - If VERSION is not specified, the latest release will be installed
#
# This script will:
#   - Download and install the latest or specified node_exporter binary
#   - Configure a systemd service for node_exporter
#   - Enable and start node_exporter at boot
#   - Verify the /metrics endpoint is working via curl
#   - Perform systemd and HTTP verification
#
# =============================================================================

# --------- CONFIGURATION ---------
VERSION="${1:-}"    # Optional: pass version as argument, otherwise fetch latest
OS="linux"          # OS: linux, darwin, windows
ARCH="amd64"        # Architecture: amd64, arm64, etc.
DOWNLOAD_DIR="$HOME/downloads"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
BINARY_PATH="/usr/local/bin/node_exporter"
NODE_EXPORTER_PORT=9100
# ---------------------------------

# Fetch latest release if VERSION not specified
if [[ -z "$VERSION" ]]; then
    echo "Fetching latest Node Exporter release..."
    VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
        | grep '"tag_name":' \
        | sed -E 's/.*"v([^"]+)".*/\1/')
    if [[ -z "$VERSION" ]]; then
        echo "Error: Could not fetch latest version."
        exit 1
    fi
fi

echo "Using Node Exporter version: $VERSION"

# Check if installed version matches requested version
if [[ -x "$BINARY_PATH" ]]; then
    INSTALLED_VERSION=$("$BINARY_PATH" --version | head -n1 | awk '{print $3}')
    if [[ "$INSTALLED_VERSION" == "$VERSION" ]]; then
        echo "Node Exporter v$VERSION is already installed. Nothing to do."
    else
        echo "Upgrading Node Exporter from v$INSTALLED_VERSION to v$VERSION..."
    fi
fi

# Construct file name and URL
FILE_NAME="node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILE_NAME}"

# Create download directory
mkdir -p "$DOWNLOAD_DIR"

# Clean up previous downloads/extractions for this version
rm -rf "${DOWNLOAD_DIR}/node_exporter-"*

# Download Node Exporter
echo "Downloading $FILE_NAME..."
wget -O "${DOWNLOAD_DIR}/${FILE_NAME}" "$URL"
if [[ $? -ne 0 ]]; then
    echo "Download failed. Check version or network."
    exit 1
fi

# Extract tarball
echo "Extracting..."
tar -xzf "${DOWNLOAD_DIR}/${FILE_NAME}" -C "$DOWNLOAD_DIR"
EXTRACTED_DIR=$(tar -tf "${DOWNLOAD_DIR}/${FILE_NAME}" | head -1 | cut -f1 -d"/")
NODE_EXPORTER_BIN="${DOWNLOAD_DIR}/${EXTRACTED_DIR}/node_exporter"

# Ensure node_exporter user exists
if ! id "node_exporter" &>/dev/null; then
    echo "Creating node_exporter user..."
    sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter
fi

# Stop service if runn

