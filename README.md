# AOEngine Online Installer
*Disclaimer: Not affiliated with the AOEngine team.*

Automated deployment and configuration pipeline for the AOEngine project. Designed to handle downloads, file backups, and environment setup for S.T.A.L.K.E.R. Anomaly, ensuring a clean and efficient installation, for advanced modpacks as well.

## Features
* **Automated Pipeline:** Fetches the latest AOEngine binaries and required resources.
* **Smart Backup:** Automatically backs up `bin`, `appdata\savedgames`,`appdata\user.ltx` and preserves your original `gamedata` folder (renamed to `gamedata_orig`).
* **Integrity Validation:** Verifies the target environment to prevent installation errors.
* **Cleanup:** Clears temporary files and shader cache for a fresh, stable start.


## Advanced CLI Params

Start parameters for more advanced users, automated deployments or mod manager integration (e.g., Mod Organizer 2):

| Switch | Alias | Description |
| :--- | :---: | :--- |
| `-Silent` | `-S` | **Unattended Mode.** Hides UI, menus, and progress bars. Bypasses critical errors to STDERR. |
| `-NoBackup` | `-NB` | **Skip Backups.** Disables file safeguarding for a faster installation. |
| `-NoLog` | `-NL` | **Disable Logging.** Stops the creation of `AOEOI_Log.txt`. |

*Example for MO2/Modlist background execution:*

```powershell
 powershell -ExecutionPolicy Bypass -File .\AOEngine-Online-Installer.ps1 -Silent
```

## Usage
1. Place `AOEngine-Online-Installer.ps1` in your main **Anomaly** directory.
2. Open PowerShell in that folder (Right-click -> "Open in Terminal").
3. Execute the script:
```powershell
    .\AOEngine-Online-Installer.ps1
```

*Note: If Windows blocks the script execution, use this command instead:*
```powershell
    powershell -ExecutionPolicy Bypass -File .\AOEngine-Online-Installer.ps1
```

## Why this script?
Designed to automate the repetitive manual installation process, minimize user error, and ensure safe backups of critical files.
It’s a community-driven solution for anyone tired of manual file management.

## Will this ruin my PC?
No. Copy/paste this script into any AI and it will give you the exact same answer.
The code is 100% transparent and open-source - it does exactly what it's supposed to do. It does NOT download viruses, it does NOT touch your system files, and it automatically creates backups of your game files before making any changes.

## Important Note
* **Backup:** Your files are backed up in the `backup of overwritten files` folder created by the script.
* **Requirements:** Requires modern Windows (10 1803+ / 11) for the `tar.exe` utility.


## Credits
Script created with <3 by **kamil_zeus**.
