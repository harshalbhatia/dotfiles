#!/bin/bash

# Setup script for Power-Aware App Manager
# This script installs and configures the power app manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PLIST_FILE="$DOTFILES_DIR/macos/com.user.power-app-manager.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.user.power-app-manager.plist"
POWER_SCRIPT="$DOTFILES_DIR/bin/power-app-manager"

echo "🔧 Setting up Power-Aware App Manager..."

# Ensure the script is executable
if [[ -f "$POWER_SCRIPT" ]]; then
    chmod +x "$POWER_SCRIPT"
    echo "✅ Made power-app-manager executable"
else
    echo "❌ Error: power-app-manager script not found at $POWER_SCRIPT"
    exit 1
fi

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENTS_DIR"

# Copy the plist file
if [[ -f "$PLIST_FILE" ]]; then
    cp "$PLIST_FILE" "$PLIST_DEST"
    echo "✅ Copied Launch Agent plist to $PLIST_DEST"
else
    echo "❌ Error: plist file not found at $PLIST_FILE"
    exit 1
fi

# Load the Launch Agent
if launchctl load "$PLIST_DEST" 2>/dev/null; then
    echo "✅ Loaded Launch Agent"
else
    echo "⚠️  Launch Agent may already be loaded or there was an issue"
fi

# Create initial configuration
echo "📝 Creating initial configuration..."
"$POWER_SCRIPT" config

echo ""
echo "🎉 Power-Aware App Manager setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Add your apps interactively:"
echo "   $POWER_SCRIPT add"
echo ""
echo "   Or edit the configuration file manually:"
echo "   $HOME/.config/power-app-manager/apps.conf"
echo ""
echo "2. Test the setup:"
echo "   $POWER_SCRIPT status"
echo ""
echo "3. Monitor logs:"
echo "   tail -f $HOME/Library/Logs/power-app-manager.log"
echo ""
echo "🔧 App Management commands:"
echo "   $POWER_SCRIPT add               # Add an app interactively"
echo "   $POWER_SCRIPT remove            # Remove an app interactively"
echo "   $POWER_SCRIPT list              # List configured apps"
echo "   $POWER_SCRIPT list-available    # List all available apps"
echo ""
echo "🔧 Power Management commands:"
echo "   $POWER_SCRIPT start    # Force start all apps"
echo "   $POWER_SCRIPT stop     # Force stop all apps"
echo "   $POWER_SCRIPT status   # Show current status"
echo ""
echo "🗂️ To uninstall:"
echo "   launchctl unload $PLIST_DEST"
echo "   rm $PLIST_DEST"
echo ""
echo "The manager will now automatically monitor power state every 30 seconds."
echo "Apps will be started when plugged in and stopped 5 minutes after unplugging."
