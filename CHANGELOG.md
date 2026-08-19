# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-08-19

### Added
- `--quiet` flag for silent installation (log only, no console output)
- `--help` / `-h` flag to show usage instructions
- `--no-reboot` flag to skip automatic reboot
- Version number display in banner
- CHANGELOG.md

### Changed
- Verify script now checks specific firewall rule names instead of broad pattern matching
- Restore script now also resets LanmanServer and LanmanWorkstation services to manual
- Improved banner formatting with version info

### Fixed
- Verify script firewall check could produce false positives
- Restore script missed 2 services when resetting to defaults

## [1.0.0] - 2026-08-19

### Added
- Initial release
- `install.bat` - Main installer with full sharing configuration
- `verify.bat` - Post-reboot verification tool
- `restore.bat` - Restore defaults with registry backup
- README.md with full documentation
- MIT License
- Registry backup before any changes
- Logging to file
- Error handling for all operations
- SMBv1 detection (skip if already enabled)
- Support for Windows 7/8/10/11
