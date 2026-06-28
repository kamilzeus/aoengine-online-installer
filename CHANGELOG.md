# AOEngine-Online-Installer Changelog

## [1.8] - Major Update

### Added

- Added a complete recovery system:
  - New `-Recovery` parameter.
  - Automatic rollback support using `.recovery` snapshots.
  - Restores:
    - `AnomalyDX11.exe`
    - `AnomalyDX11.pdb`
    - `gamedata`
    - `savedgames`
    - `user.ltx`
  - Removes installed AOEngine artifacts during recovery.

- Added installation snapshots:
  - Creates `.recovery` before modifying game files.
  - Saves important user files and original binaries.

- Added new installer parameters:
  - `-TrustBanner` (`-TB`)
  - `-Recovery` (`-R`)
  - `-Logging` (`-L`)
  - `-Instructions` (`-I`)
  - `-GenerateHashes` (`-GH`)
  - `-SilenceErrors` (`-SE`)
  - `-DisableConsoleBeeps` (`-DCB`)

- Added trust information screen:
  - Explains what files the installer modifies.
  - Clarifies that no Windows/system files are touched.

- Added MO2 instruction display mode:
  - Run with `-Instructions` to view required mod configuration steps.

- Added SHA256 verification:
  - Downloaded files are now checked against known hashes.
  - Added optional hash generation mode.

- Added archive handling improvements:
  - Automatic detection of 7z archives.
  - Native extraction support.
  - Better ZIP folder detection.

- Added download retry system:
  - Failed downloads retry up to 3 times.
  - Better error reporting for network failures.

- Added hidden temporary working directories:
  - `.aoeneeded`
  - `.extract`
  - `.stage_install`


---

### Changed

- Completely rewritten installer architecture:
  - Replaced simple script flow with separated handlers.
  - Added dedicated systems for:
    - Logging
    - Installation
    - Recovery
    - Extraction
    - File deletion
    - Snapshots

- Updated version system:
  - From `1.6.0.5 (hotfix)` → `1.8`

- Improved logging:
  - New optional log file system.
  - Logs timestamps and installer events.

- Improved error handling:
  - Added global exception handling.
  - Better crash messages.
  - Recovery instructions after failed installation.

- Changed backup system:
  - Old `backup of overwritten files` replaced with `.recovery`.
  - Recovery data is now structured and reusable.

- Changed gamedata handling:
  - Old:
    - Rename `gamedata` → `gamedata_orig`
  - New:
    - Rename `gamedata` → `gamedata_old`
    - Safer installation flow.

- Changed extraction system:
  - Removed dependency on manual folder searching.
  - Added automatic archive structure detection.

- Changed file copying:
  - Replaced some PowerShell copy operations with safer custom copy functions.


---

### Fixed

- Fixed unsafe deletion behavior:
  - Added deletion whitelist.
  - Installer can no longer accidentally remove unrelated folders.

- Fixed potential deletion of:
  - Windows directory.
  - Installer root directory.
  - Recovery backups.

- Fixed symlink/junction risks:
  - Installer now detects linked game folders.

- Fixed permission problems:
  - Added folder write tests.
  - Added administrator requirement detection.

- Fixed corrupted download handling:
  - Empty downloads are now rejected.

- Fixed extraction issues with different archive layouts.

- Fixed missing binary handling:
  - Installer now validates required files before continuing.


---

### Security Improvements

- Added URL validation:
  - Installer only accepts approved sources:
    - GitHub
    - Google Drive

- Added file integrity verification:
  - SHA256 checks prevent modified/corrupted downloads.

- Added safer delete system:
  - Every deletion request is validated.

- Added restricted path protection:
  - Prevents dangerous operations outside the Anomaly folder.


---

### Removed

- Removed old:
  - `Assert-DeploymentStage` protection system.
  - Manual download folder reuse logic.
  - Simple backup folder workflow.

- Removed automatic MO2 instructions after installation.
  - Instructions are now displayed with `-Instructions`.


---

### Developer / Internal Changes

- Added:
  - `Get-CanonicalPath`
  - `Lightweight`
  - `Heavyweight`
  - `ExtractAuto`
  - `Extraction`
  - `CreateSnapshot`
  - `TheRecovery`

- Improved code structure and maintainability.

- Added stricter PowerShell behavior:
  - `Set-StrictMode`
  - Better exception handling.

---

## Summary

AOEngine Installer 1.8 is a complete rewrite focused on:

- Safety
- Recovery
- File integrity
- Better error handling
- More reliable installation
- Easier debugging

The installer is now closer to a proper deployment tool instead of a simple installation script.
