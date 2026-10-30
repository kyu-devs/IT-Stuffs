# Validation and acceptance

## Automated checks

Verified on 2026-10-30 using Windows PowerShell 5.1:

- `powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1`:
  **38 passed, 0 failed**; exit code 0.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tests\validate.ps1`:
  **14 PowerShell files, 14 Batch menus, 80 system-action routes; zero errors**;
  exit code 0.
- Interactive smoke test: visible choices before input; child and parent exit 0.

These results are automated/isolated validation, not physical-printer acceptance.

Run `tests/run.ps1` with Windows PowerShell 5.1. It exercises actual pure
functions and isolated operation orchestration, replacing Windows mutations
with controlled functions. Native command tests execute only cmd.exe exit codes;
TCP checks use a temporary loopback listener. No real repairs, authentication,
activation, registry/service changes, queue deletion, or print jobs run.

Coverage includes keyword specificity, supported categories, error-code/HRESULT
decoding, UNC validation and ambiguity, duplicate shares, verified connection
presence, native failure/reboot statuses, rejected executable names, Office XML,
key format, power-plan identifiers, source/destination overlap, path boundaries,
subnet sizing, skipped/failed steps, spooler recovery, update-service recovery,
rollback of a newly created unused printer port, ancestor-junction refusal,
custom spool-directory detection, dependency-ordered audio recovery, and
preservation of existing registry keys.

`tests/validate.ps1` parses every project PowerShell file, checks Batch label
targets and file references, and checks that routed system actions have a
dispatcher branch. These are structural checks, not execution of every menu.

The harmless `tests/interactive-smoke.ps1` check was also run with console input:
both numbered choices were visible before input, `OK` was accepted, and the
child/parent completed with exit code zero. No toolkit action was executed.

## Controlled manual acceptance still required

Use disposable Windows VMs for consequential repairs and a real host/client
pair for printer acceptance. Save the starting configuration and results.

| Area | Scenario and expected observation |
| --- | --- |
| Printer host | Select one trusted LAN; verify firewall/profile backup and running services; leave other network profiles unchanged |
| Printer authentication | Valid host account connects; incorrect password is reported; no Guest/SMB signing/RPC/driver-policy weakening |
| Printer discovery | Same share name on two hosts remains separate; restricted discovery permits full UNC entry; explicit host lookup is bounded |
| Printer drivers | Exact signed driver works; missing, incompatible, and policy-blocked drivers produce guidance without disabling protections |
| Direct printer | RAW TCP 9100 device with approved driver; failed installation removes only its new unused port; IPP/WSD uses Windows settings |
| Printer queues | Restart retains jobs; explicit clearing removes only standard queue job files; locked-file failure restores spooler and reports failure |
| Printer output | Optional test page reaches paper; verify printer hardware, paper, consumables, and queue drain separately |
| Printer restore | Restore saved profile/firewall/service state on the same PC; verify organization policy has not overridden it |
| Windows activation | Licensed test VM: matching/mismatched key, offline/KMS failure, and verified LicenseStatus; retain keys and KMS configuration on failure |
| Office | Validate signature, product/channel/architecture, existing installations and installer exit codes; verify apps and separate licensing state |
| Network | Multiple adapters, custom/VPN DNS, DHCP failure, remote-session disruption, static IP backup, IPv6 binding; retain firewall rules |
| Servicing | DISM reboot code, unresolved SFC findings, update-cache name collisions, service restart failure, existing backup preservation |
| Privacy/performance | Missing and existing registry values restore exactly; policy-managed values report errors; power plan exists and becomes active |
| Files/backups | Paths with spaces/apostrophes, redirected Desktop, junctions, locked files, full destination, Robocopy failure, EFS/cloud data |
| Remote/security | Home edition refuses RDP hosting; supported edition uses NLA; 1149 query reads RemoteConnectionManager; audit windows do not duplicate events |
| Recovery | Locked local account unlocks without enabling a disabled account; domain accounts defer to domain administration; WinRE/BitLocker guidance remains informational |
| Problem solver | Ten supported categories plus unknown input; decline/failed repair states remain accurate; no unsupported hardware-failure verdict |
| External code | Cancel before download/execution; review actual retained code; detect download/parse/signature errors; no success claim based only on window closure |

## Limits

Automated tests and parsing do not prove successful physical printing, licensed
activation, servicing recovery, or compatibility with every Windows build and
policy. Hardware faults, encrypted or inaccessible data, organization-managed
policies, and unsupported or defective drivers may require vendor/admin help.
Queue cleanup checks global and per-printer spool-directory configuration and
refuses custom locations rather than deleting the wrong queue's files.
An elevated connection under another administrator identity is not a connection
in the original user's profile. Existing insecure settings from earlier toolkit
versions require administrator review; this update does not silently reset them.
