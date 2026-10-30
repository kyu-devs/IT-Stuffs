# ONYX IT DEPARTMENT TECH TOOLS / KyuTools

A portable Windows helpdesk toolkit with 14 terminal menus for diagnostics,
maintenance, licensed Windows/Office setup, printer support, and guided repairs.
It uses Batch, Windows PowerShell 5.1, and built-in Windows tools.

The reliability update replaces consequential menu actions with checked
PowerShell operations. A completed command is not proof that a PC problem is
fixed: review its findings and retest the original symptom.

## Run

1. Review the code and open `KyuTools.bat`. Accept UAC to perform administrative actions.
2. Enter the local menu password, currently `kyu04`, defined in `modules/pass.ps1`.
3. Choose a module. Actions with significant effects explain their scope and
   require typing `YES`; cancelling retains the existing configuration.

Windows 10/11 and Windows PowerShell 5.1 are the intended environment. Individual
features depend on edition, installed Windows components, drivers, policies,
permissions, connectivity, and device capabilities. Optional Windows features
and services may be unavailable or disabled by an administrator.

The password prompt is a convenience gate. The password is in source and modules
can run directly. It is not an access-control boundary.

## Modules

| Menu | Module | Current behavior |
| --- | --- | --- |
| 1 | Windows Activation and Offices | Verified Windows license status; validated licensed product keys; Office deployment, removal, and official activation help |
| 2 | Network and Internet | DNS queries, adapter selection, backed-up DNS changes, checked resets, adapter IPv6 controls; firewall policy retained |
| 3 | Maintenance | Checked SFC/DISM, update-cache renaming, bounded temporary-file cleanup, disk checks, exported Application/System event logs |
| 4 | System Information | CPU/RAM/GPU/disk information; battery and timestamped system reports using the actual Desktop folder |
| 5 | Privacy | Edition-dependent registry policies with exact prior-value backups and explicit restoration; hosts file and service configuration retained |
| 6 | Performance | Checked power-plan activation, memory/process information, reversible UI/gaming preferences, temporary service comparison |
| 7 | File and Disk | Focused large-file scans, SHA256 hashes, media-aware drive optimization, scoped ownership, links, and Explorer visibility |
| 8 | Printer and Device Sharing | Host/client diagnostics, authenticated sharing, driver inventory, UNC connections, direct TCP/IP setup, spooler/queue tools, optional test pages |
| 9 | IT Helpdesk | Checked boot changes, session Explorer restart, update repair, policy refresh, targeted app repair guidance |
| 10 | Remote Management | Edition-aware RDP configuration with NLA, validated host input, remote consoles/shares, local network observation |
| 11 | Security | Login/session/audit utilities, correct RDP authentication event channel, recent files, startup entries, Defender history |
| 12 | All in One Utilities | Download WinUtil to a reviewable file, display its hash, review in Notepad, then explicitly choose execution |
| 13 | Account Recovery | Official recovery guidance, actual local lockout-flag clearing, BitLocker/WinRE information, checked Robocopy backups |
| 14 | Custom Problem Solver | Predefined keyword recipes, more specific matching, completed/failed/skipped step reporting, evidence-based escalation |

## Printer workflow

Start with **Diagnose and export report** on the affected PC. For a shared
printer, check the host PC as well as the client.

1. Confirm the printer itself works and the host is awake on the trusted LAN.
2. On the host, use **Enable authenticated sharing**, selecting the correct
   interface. It backs up profile/firewall/service state, configures Private or
   Domain firewall rules, and starts permitted services. It does not change
   domain network classification or enable disabled services behind policy.
3. Use **Share a local printer** and record `\\HOST\SHARE`.
4. On the client, use **Connect to a shared printer**. Query an explicit host or
   cached neighbors, choose a discovered printer, or enter its full UNC path.
5. If credentials are needed, authenticate through Windows/File Explorer using
   a host or domain account and its password. A Windows Hello PIN is not a
   network account password. The toolkit does not read or log network passwords.
6. Install the exact approved signed driver as administrator when requested.
   The correct model and x64/x86/ARM64 architecture matter.
7. Confirm Windows enumerates the connection, then use **Optional physical test
   page** to verify delivery. This action requires confirmation and uses paper.

Discovery can be blocked by firewall, RPC, credentials, VLANs, or device
protocols. Failure to enumerate does not prove the printer is absent. A manual
UNC path remains available. Identical share names on different hosts stay
separate. An IPP/WSD device should be added through Windows printer settings;
the direct TCP/IP option specifically requires RAW TCP 9100 and an installed
compatible driver.

Spooler restart retains queued jobs. **Clear stuck local queue** is separate and
explicit: it removes pending `.SPL`/`.SHD` files from the standard local queue,
then restores the spooler even if deletion fails. It does not delete driver
packages. Custom global/per-printer spool directories are detected and refused;
they need administrator inspection.

Routine repairs retain SMB signing, RPC privacy, authenticated access, and
administrator-only driver installation. They do not enable Guest, anonymous
access, SMB1, or blanket Point and Print bypasses. Existing insecure settings
from previous versions are reported where available; they are not silently
reconfigured because organization policy may own them.

Connections/default printers are associated with the executing Windows user.
If UAC uses a different administrator account, add the printer in the intended
user session too.

## Windows and Office licensing

Windows activation is checked using `SoftwareLicensingProduct` state after the
activation request. Existing keys/KMS configuration are retained unless the user
explicitly supplies a new valid-format key. A key's format does not establish
that it is licensed or valid for the installed edition.

Office deployment supports these licensed enterprise products:

| Choice | Product | Channel |
| --- | --- | --- |
| 2021 | ProPlus2021Volume | PerpetualVL2021 |
| 2024 | ProPlus2024Volume | PerpetualVL2024 |
| 365 | O365ProPlusRetail | Current |

The installer must pass Microsoft Authenticode validation. Existing Click-to-Run
architecture is respected; unsupported ARM64 deployment is handed off to the
official installer. Word, Excel, PowerPoint and classic Outlook are included;
other apps are excluded through deployment configuration. Existing MSI products
are not removed automatically. Retail perpetual products need their matching
installer and license. Installing Office does not activate or license it.

Office activation guidance uses supported Microsoft account/subscription or
organization KMS/MAK paths. Previous MAS/Ohook download-and-execute shortcuts and
unverified permanent-activation claims have been replaced. The bundled third-party
OfficeScrubber remains an explicitly confirmed interactive removal option.

## Reports, backups, and logs

- Reports use Windows' actual Desktop location, including redirection/OneDrive.
- Checked-operation logs: `%LOCALAPPDATA%\KyuTools\Logs\YYYY-MM-DD.log`.
- Configuration backups: `%LOCALAPPDATA%\KyuTools\Backups\<timestamp-id>\`.
- Privacy/performance restoration accepts the exact `registry-settings.clixml`
  file saved before a change. Printer sharing has its own restore action for
  `printer-sharing.clixml`.
- Network snapshots and permission descriptors are retained for administrator
  review. They are not automatically equivalent to a full system restore point.

Logs record action/exit status without native argument values. Keep reports and
backups private: they can include usernames, device information, network details,
and configuration. Review them before sharing.

`launch.ps1` is an optional GitHub download bootstrapper. It uses a unique
temporary directory, retains downloaded source for inspection, and requires
confirmation before elevation. Downloading the current branch is not a pinned
or independently authenticated release.

## Development and validation

No additional packages are needed for the checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\validate.ps1
```

Tests isolate system mutations; they do not activate software, modify Windows
settings, clear real queues, or print. They cannot establish physical printer
compatibility or guarantee repairs on every PC. See [validation and manual
acceptance](docs/VALIDATION.md), [project context](docs/PROJECT_CONTEXT.md), and
[the implementation plan](docs/superpowers/plans/2026-10-30-toolkit-reliability.md).

Creator: Kyu (mong-g). Contributor: themarneilx.
