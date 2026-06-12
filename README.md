# AOEngine Online Installer
Disclaimer: Not affiliated with the AOEngine team.

Automated deployment and configuration pipeline for the AOEngine project. Designed to handle downloads, file backups, and environment setup for S.T.A.L.K.E.R. Anomaly, ensuring a clean and efficient installation, for advanced modpacks as well..

## Features
* **Automated Pipeline:** Fetches the latest AOEngine binaries and required resources.
* **Smart Backup:** Automatically backs up `bin`, `appdata\savedgames`,`appdata\user.ltx` and preserves your original `gamedata` folder (renamed to `gamedata_orig`).
* **Integrity Validation:** Verifies the target environment to prevent installation errors.
* **Cleanup:** Clears temporary files and shader cache for a fresh, stable start.

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


## Important Note
**Backup:** Your files are backed up in the `backup of overwritten files` folder created by the script.
**Requirements:** Requires modern Windows (10 1803+ / 11) for the `tar.exe` utility.


## Credits
Script created by **kamil_zeus**.
