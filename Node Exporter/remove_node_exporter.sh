#!/bin/bash
# =============================================================================
# Script: Remove Prometheus Node Exporter
#
# Creator: The Digital Relic (TDR)
# Date: 2025-09-21
# Copyright (c) 2025 The Digital Relic (TDR)
#
# Usage:
#   ./remove_node_exporter.sh
#
# This script will:
#   - Stop the node_exporter systemd service
#   - Disable the service from starting at boot
#   - Remove the node_exporter binary
#   - Remove old backup binaries
#   - Remove the systemd service file
#   - Remove the node_exporter user
#   - Clean any downloaded files in the default download directory
#
# =============================================================================

# --------- CONFIGURATION ---------
DOWNLOAD_DIR="$HOME/downloads"
BINARY_PATH="/usr/local/bin/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
USER="node_exporter"
# ---------------------------------

echo "Stopping Node Exporter service (if running)..."
if systemctl is-active --quiet node_exporter; then
    sudo systemctl stop node_exporter
fi

echo "Disabling Node Exporter service..."
sudo systemctl disable node_exporter

echo "Removing systemd service file..."
if [[ -f "$SERVICE_FILE" ]]; then
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
fi

echo "Removing Node Exporter binary..."
if [[ -f "$BINARY_PATH" ]]; then
    sudo rm -f "$BINARY_PATH"
fi

echo "Removing old backup binaries..."
sudo rm -f /usr/local/bin/node_exporter.bak_*

echo "Removing node_exporter user..."
if id "$USER" &>/dev/null; then
    sudo userdel "$USER"
fi

echo "Cleaning downloaded files..."
rm -rf "${DOWNLOAD_DIR}/node_exporter-"*

echo "Node Exporter has been completely removed."

