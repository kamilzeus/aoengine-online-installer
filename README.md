# AOEngine Online Installer

*Disclaimer: Not affiliated with the AOEngine team, at least not yet. If installer script doesn't work, don't ask them, ask ME. Contact is at the bottom of the page.*

Automated deployment and configuration pipeline for the AOEngine project.

Works with G.A.M.M.A flawlessly, not sure about other modpacks, they might have other requirements.

Designed to simplify AOEngine installation for S.T.A.L.K.E.R. Anomaly by handling downloads, integrity checks, backups, installation, and recovery operations.

Built with safety and reliability in mind, especially for large modpacks and Mod Organizer 2 based setups.

---

(see the changes in [CHANGELOG.md](CHANGELOG.md))
## Features

* **Automated Installation Pipeline**
  * Downloads required AOEngine components automatically.
  * Extracts and installs required files.
  * Handles the complete deployment process.

* **Recovery System**
  * Creates a restore snapshot before installation.
  * Can recover previous files if something goes wrong.
  * Restores:
    * binaries
    * `gamedata`
    * `appdata\savedgames`
    * `appdata\user.ltx`

* **Integrity Validation**
  * SHA256 verification for downloaded files.
  * Prevents corrupted or modified downloads.
  * Validates required files before installation.

* **Safe File Handling**
  * Protected deletion system.
  * Prevents accidental removal of unrelated files.
  * Detects unsupported symlink/junction game folders.

* **Automatic Cleanup**
  * Removes temporary installation files.
  * Clears shader cache after deployment.


---

# Requirements

* Windows 10 (1803+) / Windows 11
* PowerShell 5.1+
* S.T.A.L.K.E.R. Anomaly installation
* Installer placed inside the main Anomaly directory


---

# Usage

1. Place:

```

AOEngine-Online-Installer.ps1

````

inside your main **S.T.A.L.K.E.R. Anomaly** folder.

2. Open Terminal / PowerShell in that directory.

3. Run:

```powershell
.\AOEngine-Online-Installer.ps1
````

If Windows blocks script execution:

```powershell
powershell -ExecutionPolicy Bypass -File .\AOEngine-Online-Installer.ps1
```

---

# Command Line Parameters

Advanced users, automation tools, and Mod Organizer 2 setups can use:

| Switch                 | Alias  | Description                                  |
| ---------------------- | ------ | -------------------------------------------- |
| `-TrustBanner`         | `-TB`  | Shows installer safety information           |
| `-Recovery`            | `-R`   | Restores previous installation snapshot      |
| `-Silent`              | `-S`   | Runs installer without normal console output |
| `-NoBackup`            | `-NB`  | Skips snapshot creation                      |
| `-Logging`             | `-L`   | Enables installation logging                 |
| `-Instructions`        | `-I`   | Displays MO2 configuration instructions      |
| `-GenerateHashes`      | `-GH`  | Generates SHA256 hashes for downloaded files |
| `-SilenceErrors`       | `-SE`  | Prevents waiting on errors                   |
| `-DisableConsoleBeeps` | `-DCB` | Disables installer sounds                    |

Example:

```powershell
.\AOEngine-Online-Installer.ps1 -Silent
```

---

# Recovery

If installation fails or you want to revert changes:

```powershell
.\AOEngine-Online-Installer.ps1 -Recovery
```

The recovery system can restore your previous installation state using the snapshot created before deployment.

---

# Mod Organizer 2

After installation, run:

```powershell
.\AOEngine-Online-Installer.ps1 -Instructions
```

to display required MO2 configuration steps.

---

# Why this script?

Manual AOEngine installation can require many repetitive file operations and can easily lead to mistakes.

This installer was created to:

* Reduce manual setup steps.
* Prevent user mistakes.
* Keep backups before modifying files.
* Provide a safer installation workflow.

---

# Security / Trust

**Will this damage my PC?**

No.

The script is open-source and fully readable.

It only operates inside the S.T.A.L.K.E.R. Anomaly installation directory.

It does **not**:

* Modify Windows system files.
* Install background services.
* Modify registry entries.
* Add startup programs.
* Access personal folders.

All operations are limited to the game directory where the installer is placed.

---

# Project Structure

During installation the script may create temporary folders:

```
.aoeneeded
.extract
.stage_install
.recovery
```

These are used for downloading, extraction, staging, and recovery purposes.

---

# Credits

Created with <3 by **kamil_zeus** (kamil_zeus on Discord.)

Modifications are allowed, but please keep the original attribution.
