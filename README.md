# Windows LAN Sharing Setup

Automatically configure Windows file and printer sharing across LAN networks. Works with mixed environments including older Windows versions (Windows 7/8/10/11) by enabling SMBv1 support.

## Features

- Enables Network Discovery and File/Printer Sharing
- Configures required Windows services (Function Discovery, SSDP, UPnP, SMB)
- Enables SMBv1 for compatibility with legacy Windows systems
- Sets network profile to Private for LAN access
- Configures registry settings for guest access and anonymous connections
- Automatic registry backup before any changes
- Post-installation verification tool
- One-click restore to default settings
- Detailed logging of all operations

## Files

| File | Description |
|------|-------------|
| `install.bat` | Main installer - configures sharing settings |
| `verify.bat` | Post-reboot verification tool |
| `restore.bat` | Restore all settings to Windows defaults |

## How It Works

```
install.bat
    │
    ├── Backup registry (auto-saved to registry-backup/)
    ├── Set network profile → Private
    ├── Enable firewall rules (Network Discovery + File Sharing)
    ├── Start & auto-enable 6 required services
    ├── Enable SMBv1 (skip if already enabled)
    ├── Configure registry for guest/anonymous access
    └── Reboot in 10 seconds (Ctrl+C to cancel)

verify.bat (after reboot)
    │
    ├── Check network profile status
    ├── Verify firewall rules
    ├── Check all services running
    ├── Confirm SMBv1 state
    ├── Verify registry settings
    ├── List shared folders
    └── Show access test instructions

restore.bat (if something goes wrong)
    │
    ├── Import registry backups
    ├── Reset network profile → Automatic
    ├── Disable sharing firewall rules
    └── Reset services to manual
```

## Quick Start

1. **Download** - Clone or download this repository
2. **Install** - Right-click `install.bat` > Run as Administrator
3. **Reboot** - System will reboot automatically after 10 seconds
4. **Verify** - After reboot, run `verify.bat` to confirm settings

```
git clone https://github.com/ngodingsendiri/Sharingwindows.git
cd Sharingwindows
install.bat
```

### Command Line Options

```bash
# Normal install (reboots after 10 seconds)
install.bat

# Install without reboot (manual reboot required)
install.bat --no-reboot
```

## Requirements

- Windows 7 / 8 / 10 / 11
- Administrator privileges
- PowerShell (pre-installed on Windows 10+)

## What It Configures

### Services
| Service | Description |
|---------|-------------|
| fdPHost | Function Discovery Provider Host |
| FDResPub | Function Discovery Resource Publication |
| SSDPSRV | SSDP Discovery |
| upnphost | UPnP Device Host |
| LanmanServer | SMB Server |
| LanmanWorkstation | SMB Client |

### Registry Settings
| Key | Value | Purpose |
|-----|-------|---------|
| AllowInsecureGuestAuth | 1 | Allow guest login to SMB shares |
| everyoneincludesanonymous | 1 | Include anonymous in Everyone group |
| restrictanonymous | 0 | Allow anonymous enumeration |
| AutoShareWks | 1 | Enable admin share auto-creation |

### Firewall Rules
- Network Discovery
- File and Printer Sharing

## Usage in Mixed Environments

This tool is designed for networks with a mix of old and new Windows versions:

- **Windows 7/8** - SMBv1 is enabled by default, no additional config needed
- **Windows 10/11** - SMBv1 is disabled by default, this script enables it

> **Note:** If all PCs run Windows 10 or newer, you may want to use SMBv2/v3 only for better security. SMBv1 is only needed for legacy compatibility.

## Restore Defaults

To undo all changes and restore Windows default settings:

1. Run `restore.bat` as Administrator
2. Confirm the operation
3. Reboot when prompted

## Logging

All operations are logged to `sharing-setup.log` in the same directory. The log includes:
- Success/failure status for each operation
- Error details if any operation fails
- Registry backup locations

## Troubleshooting

### Sharing not working after install?
1. Run `verify.bat` to check which settings are not active
2. Ensure both PCs are on the same network/subnet
3. Check if third-party firewall software is blocking connections
4. Try accessing `\\COMPUTERNAME\` from the other PC

### Can't see other computers?
1. Verify Network Discovery is enabled in Firewall
2. Ensure all PCs have the same Workgroup name
3. Check that required services are running

### Permission denied errors?
- Make sure you're running the scripts as Administrator
- Check User Account Control (UAC) settings

## License

MIT License - Feel free to use, modify, and distribute.
