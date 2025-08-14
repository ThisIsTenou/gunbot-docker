#!/bin/bash
set -e

ZIP_URL="https://gunthy.org/downloads/gunthy_linux.zip"
CONFIG_FILE="/opt/gunthy/config.js"
DIST_DIR="/opt/gunthy.dist"

# --- BOOTSTRAP ON EMPTY VOLUME ---
if [ ! -f "/opt/gunthy/gunthy-linux" ]; then
    echo "No installation found in volume. Copying initial files..."
    cp -r "$DIST_DIR"/* /opt/gunthy/
    chmod +x /opt/gunthy/gunthy-linux
fi

# --- UPDATE STEP ---
if [ "$GUNTHY_UPDATE_ON_START" = "true" ]; then
    echo "Updating Gunthy from $ZIP_URL..."

    TMP_DIR=$(mktemp -d)
    curl -sL "$ZIP_URL" -o "$TMP_DIR/gunthy_linux.zip"

    echo "Unpacking update..."
    unzip -q "$TMP_DIR/gunthy_linux.zip" -d "$TMP_DIR"

    echo "Contents of update package:"
    ls -al "$TMP_DIR"

    cd /opt/gunthy

    echo "Removing old files..."
    rm -rf cs gui node_modules tulind gunthy-linux || true

    echo "Copying updated files..."
    [ -d "$TMP_DIR/cs" ] && cp -r "$TMP_DIR/cs" .
    [ -d "$TMP_DIR/gui" ] && cp -r "$TMP_DIR/gui" .
    [ -d "$TMP_DIR/node_modules" ] && cp -r "$TMP_DIR/node_modules" .
    [ -d "$TMP_DIR/tulind" ] && cp -r "$TMP_DIR/tulind" .
    [ -f "$TMP_DIR/gunthy-linux" ] && cp "$TMP_DIR/gunthy-linux" . && chmod +x gunthy-linux

    rm -rf "$TMP_DIR"
    echo "Update complete."
fi

# --- CONFIG OVERRIDES ---
if [ -f "$CONFIG_FILE" ]; then
    echo "Applying environment variable overrides to config.js..."
    TMP_CONFIG=$(mktemp)
    cp "$CONFIG_FILE" "$TMP_CONFIG"

    [ -n "$GUNTHY_GUI_START" ] && jq --argjson val "$GUNTHY_GUI_START" '.GUI.start = $val' "$TMP_CONFIG" > "$TMP_CONFIG.tmp" && mv "$TMP_CONFIG.tmp" "$TMP_CONFIG"
    [ -n "$GUNTHY_GUI_PORT" ] && jq --argjson val "$GUNTHY_GUI_PORT" '.GUI.port = $val' "$TMP_CONFIG" > "$TMP_CONFIG.tmp" && mv "$TMP_CONFIG.tmp" "$TMP_CONFIG"
    [ -n "$GUNTHY_GUI_HTTPS" ] && jq --argjson val "$GUNTHY_GUI_HTTPS" '.GUI.https = $val' "$TMP_CONFIG" > "$TMP_CONFIG.tmp" && mv "$TMP_CONFIG.tmp" "$TMP_CONFIG"
    [ -n "$GUNTHY_GUI_KEY" ] && jq --arg val "$GUNTHY_GUI_KEY" '.GUI.key = $val' "$TMP_CONFIG" > "$TMP_CONFIG.tmp" && mv "$TMP_CONFIG.tmp" "$TMP_CONFIG"
    [ -n "$GUNTHY_GUI_CERT" ] && jq --arg val "$GUNTHY_GUI_CERT" '.GUI.cert = $val' "$TMP_CONFIG" > "$TMP_CONFIG.tmp" && mv "$TMP_CONFIG.tmp" "$TMP_CONFIG"

    mv "$TMP_CONFIG" "$CONFIG_FILE"
fi

echo "Starting Gunthy..."
exec "$@"
