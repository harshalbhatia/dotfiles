# Power-Aware App Manager

A macOS automation system that intelligently manages applications based on power state. Apps are automatically started when plugged into AC power and stopped after a configurable delay when running on battery.

## 🎯 Features

- **Smart Power Detection**: Automatically detects AC vs battery power
- **Smart Restart Logic**: Only restarts apps that *power manager* stopped, not user-quit apps
- **Silent Background Startup**: Apps start hidden without interrupting your work
- **LaunchAgent Management**: Manages both apps and system services (updaters)
- **Graceful App Management**: Uses proper app termination methods (AppleScript quit before force kill)
- **5-Minute Grace Period**: Prevents unnecessary app closure during brief power outages
- **Interactive App Selection**: Browse and select from all installed applications
- **Robust App Detection**: Uses multiple methods (bundle ID, process name, path) for reliable app detection
- **Configurable Delay**: Customize how long to wait before stopping apps on battery
- **Comprehensive Logging**: Track all power state changes and app management actions

## 🚀 Quick Start

### Installation

1. **Install the system:**
   ```bash
   ./script/setup-power-app-manager.sh
   ```

2. **Add applications to manage:**
   ```bash
   ./bin/pam add
   ```

3. **Check status:**
   ```bash
   ./bin/pam status
   ```

That's it! The system will now automatically monitor power state changes every 30 seconds.

## 📱 Commands

### App Management
- `pam add` - Add an app interactively from all installed apps
- `pam remove` - Remove an app interactively
- `pam list` - List currently configured apps
- `pam list-available` - Browse all installed applications
- `pam refresh` - Refresh the cache of available apps

### Power Management
- `pam start` - Smart start (only previously running apps, silently)
- `pam force-start` - Force start all configured apps
- `pam stop` - Stop all configured apps and save state
- `pam status` - Show current power state and app status
- `pam monitor` - Run monitoring once (automatic via Launch Agent)

### Configuration
- `pam config` - Show configuration file location

## ⚙️ How It Works

### Power State Logic
1. **On AC Power**: All configured apps are started immediately
2. **On Battery**: Apps continue running for the configured delay period (default: 5 minutes)
3. **After Delay**: Apps are gracefully terminated to preserve battery

### App Detection & Management
- **Discovery**: Scans `/Applications`, `/System/Applications`, and uses Spotlight (`mdfind`)
- **Storage**: Apps stored with full metadata: `"App Name|/Path/to/App.app|bundle.identifier"`
- **Starting**: Tries app path first, falls back to app name
- **Stopping**: Attempts graceful AppleScript quit, falls back to process termination

### Background Monitoring
- **Launch Agent**: Runs automatically every 30 seconds
- **State Tracking**: Remembers power state changes and timing
- **Logging**: All actions logged to `~/Library/Logs/power-app-manager.log`

## 📁 File Locations

```
~/Library/LaunchAgents/com.user.power-app-manager.plist  # Launch Agent
~/.config/power-app-manager/apps.conf                    # Main configuration
~/.config/power-app-manager/state                        # Power state tracking
~/.config/power-app-manager/running_apps_state           # Smart restart app state
~/.config/power-app-manager/running_agents_state         # Smart restart agent state
~/.config/power-app-manager/available_apps.cache         # App discovery cache
~/Library/Logs/power-app-manager.log                     # Main log file
~/Library/Logs/power-app-manager-stdout.log              # System stdout
~/Library/Logs/power-app-manager-stderr.log              # System stderr
```

## 🔧 Configuration

### Basic Settings

Edit `~/.config/power-app-manager/apps.conf`:

```bash
# Delay before stopping apps on battery (in minutes)
DELAY_MINUTES=5

# Managed applications (added via 'pam add' command)
MANAGED_APPS=(
    "Rewind|/Applications/Rewind.app|com.memoryvault.MemoryVault"
    "Slack|/Applications/Slack.app|com.tinyspeck.slackmacgap"
    "Discord|/Applications/Discord.app|com.hnc.Discord"
)
```

### Delay Configuration
- `DELAY_MINUTES=0` - Stop apps immediately when unplugged
- `DELAY_MINUTES=5` - Wait 5 minutes (default, good for power outages)
- `DELAY_MINUTES=30` - Wait 30 minutes (for longer battery usage)

## 🛠 Troubleshooting

### Check if running
```bash
launchctl list | grep power-app-manager
```

### View logs
```bash
tail -f ~/Library/Logs/power-app-manager.log
```

### Test power detection
```bash
pmset -g ps
```

### Restart the service
```bash
launchctl unload ~/Library/LaunchAgents/com.user.power-app-manager.plist
launchctl load ~/Library/LaunchAgents/com.user.power-app-manager.plist
```

### Reset configuration
```bash
rm ~/.config/power-app-manager/apps.conf
./bin/pam config
```

## 🗑 Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.user.power-app-manager.plist
rm ~/Library/LaunchAgents/com.user.power-app-manager.plist
rm -rf ~/.config/power-app-manager
```

## 💡 Use Cases

### Power-Hungry Apps on AC Only
Perfect for apps that drain battery quickly:
- Video editing software (Final Cut Pro, Adobe Premiere)
- AI/ML applications (Rewind AI, local LLMs)
- Development tools (Docker, VMs, heavy IDEs)
- Background utilities (backup software, sync tools)

### Battery Preservation
Automatically stops non-essential apps when on battery:
- Social apps (Slack, Discord, WhatsApp)
- Entertainment (Spotify, streaming apps)
- Productivity tools when mobile

### Workflow Optimization
- **Plugged in**: Full productivity setup with all tools
- **On battery**: Minimal, battery-efficient setup
- **Grace period**: Handles brief disconnections seamlessly

## 🔍 Advanced Usage

### Custom App Paths
For apps in non-standard locations, you can manually edit the config:
```bash
"Custom App|/Users/username/Applications/CustomApp.app|com.custom.app"
```

### Multiple Configurations
Copy and modify the config for different scenarios:
```bash
cp ~/.config/power-app-manager/apps.conf ~/.config/power-app-manager/work.conf
cp ~/.config/power-app-manager/apps.conf ~/.config/power-app-manager/personal.conf
```

### Monitoring Integration
The logs are structured for easy monitoring:
```bash
# Watch for power changes
tail -f ~/Library/Logs/power-app-manager.log | grep "Switched to"

# Monitor app starts/stops
tail -f ~/Library/Logs/power-app-manager.log | grep -E "(Starting|Stopping)"
```

## 🤝 Contributing

The power app manager is part of your dotfiles setup. To modify:

1. Edit `bin/power-app-manager` for core functionality
2. Update `script/setup-power-app-manager.sh` for installation
3. Modify `macos/com.user.power-app-manager.plist` for scheduling
4. Test with `./bin/pam` commands

## 📝 License

Part of personal dotfiles - use and modify as needed!
