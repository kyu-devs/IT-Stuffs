# KyuTools project context

Updated 2026-10-30 after the authorized reliability upgrade. Read this alongside
README.md and VALIDATION.md. Implementation is complete in the working copy;
physical printer and controlled Windows repair acceptance remains outstanding.

## Purpose and execution

ONYX IT DEPARTMENT TECH TOOLS is a portable Windows helpdesk toolkit using
cmd.exe and Windows PowerShell 5.1. KyuTools.bat checks the administrator token,
requests elevation, runs the convenience password prompt, and opens 14 menus.
The hardcoded password is not an access-control boundary.

Batch menus delegate consequential operations to modules/system_tools.ps1.
Checked operations log action/exit status under LocalApplicationData/KyuTools.
Library imports have no repair side effects. Actual administrator operations
are confirmed at runtime, and tests replace mutation boundaries with doubles.

## File responsibilities

| File | Responsibility |
| --- | --- |
| KyuTools.bat | Elevation, password gate, main navigation |
| modules/common.ps1 | Native exit checks/live output, explicit interactive execution, host/TCP validation, safe paths, service checks, backup/report locations, bounded subnet targets |
| modules/system_tools.ps1 | Checked Windows/Office, network, servicing, privacy, performance, files, boot, RDP, recovery, and external-tool actions |
| modules/printer_core.ps1 | UNC validation, printer error decoding, host/share discovery, verified connection presence, spool configuration guards and cleanup, diagnostic data |
| modules/printer_tools.ps1 | Printer menu, host setup/restoration, driver inventory, direct TCP/IP setup, default printer, optional test page, logs/reporting |
| modules/connect_printer.ps1 | Compatibility entry point for the shared-printer connection workflow |
| modules/troubleshoot.ps1 | Keyword recipes, step result accounting, physical checklists without unsupported hardware verdicts |
| modules/network_scan.ps1 | PS 5.1-compatible network observation with configured subnet boundaries and source-labeled identity hints |
| modules/logon_audit.ps1 | Login/session/audit utilities; overlapping live event windows deduplicated by record ID |
| launch.ps1 | Unique-directory GitHub download, code-review notice and explicit elevated launch |
| fix_wmic.ps1 | Historical source migration helper; do not run as an end-user repair |
| bin/OfficeScrubber.cmd | Existing third-party interactive Office removal utility; unchanged |
| tests/run.ps1 | Dependency-free behavioral regression runner |
| tests/validate.ps1 | PowerShell parsing and Batch route/reference integrity |
| tests/interactive-smoke.ps1 | Optional harmless child-console interaction check |

## Menu index

1. activation.bat: signed licensed Office deployment, explicit removal,
   verified Windows license state, key entry, official Office activation help.
2. network.bat: DNS/adapter controls, checked resets, actual DNS query timing.
3. maintenance.bat: SFC/DISM, cache repair, cleanup and diagnostic logs.
4. sysinfo.bat: hardware information and known-folder report exports.
5. privacy.bat: backed-up registry policies and exact saved-value restoration.
6. performance.bat: checked plans, memory information, UI/gaming preferences,
   temporary service tests and registry restoration.
7. diskutils.bat: validated file/storage operations and scoped ownership.
8. printer.bat: delegates to the expanded printer workflow.
9. ithelpdesk.bat: checked boot/session/update/policy actions and app guidance.
10. remote.bat: edition-aware RDP/NLA, validated targets and network observation.
11. security.bat: security utilities and correct RemoteConnectionManager 1149 channel.
12. allinone.bat: reviewable WinUtil download with separate execution confirmation.
13. account_recovery.bat: official guidance, actual local lockout clearing,
    checked non-mirroring backups and recovery information.
14. troubleshoot.ps1: more specific keyword matching with honest step outcomes.

## Changes and preserved inputs

Initial input contained modifications to activation.bat, diskutils.bat,
network.bat, remote.bat and sysinfo.bat plus an untracked network_scan.ps1.
These were inspected as input; higher-impact sections were replaced with checked
implementations while their intended diagnostics/scanner capabilities were kept.
No git reset, clean, commit, branch switch, merge, push or deployment was used.

Confirmed old defects addressed: automatic printer security weakening; share-name
collisions; TCP false positives; unbounded error-number matching; unchecked
success messages; Input automatic-variable collision; unsupported printer-default
command; false RAM/standby and hardware-failure claims; power-plan template GUID
activation; wrong RDP event channel; account-enable versus account-unlock mixup;
PowerShell 5.1 scanner timeout incompatibility; misleading identity fallback labels.

Previous MAS/Ohook shortcuts now lead to supported licensing guidance. Blanket
firewall reset, hosts blocking, driver-cache deletion, and automatic disabling
of printer protections are not routine repair actions. Existing insecure settings
from an older version are not silently reset; administrators should review them.

## Validation and remaining limits

The behavioral suite uses actual pure logic, controlled Windows operation
boundaries, harmless native exit codes, and loopback TCP. Structural checks
parse project scripts and verify menu/action references. An interactive child
smoke test confirmed numbered choices appear before Read-Host input.

Fresh review identified interactive output buffering, forced-stop dependency
loss, ancestor-junction backup aliasing, custom spool-directory assumptions, and
unverified identity hints. The fixes have regression coverage or a documented
interactive check. See VALIDATION.md for the final automated counts and manual
acceptance matrix.

Actual host/client authentication, signed-driver compatibility, physical output,
Office setup/licensing, and servicing effects need controlled machine testing.
Custom spool-directory cleanup is deliberately refused with guidance. Windows
edition, policies, unavailable components, credentials and hardware can prevent
automatic repair. Never claim universal or 100-percent PC repair reliability.

## Official references

- [Shared printer troubleshooting](https://support.microsoft.com/en-us/windows/hardware/printer/fix-shared-printer-connection-problems-in-windows)
- [SMB signing](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing?tabs=powershell)
- [Printer troubleshooting guidance](https://learn.microsoft.com/en-us/troubleshoot/windows-server/printing/troubleshoot-printer-guidance)
- [Office LTSC 2024 deployment](https://learn.microsoft.com/en-us/office/ltsc/2024/deploy)
- [Powercfg command options](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options)
