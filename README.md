# KyuTools v1.1

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-Batch%20%2B%20PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Shell" />
  <img src="https://img.shields.io/badge/Version-v1.1-brightgreen?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/badge/Privileges-Administrator-red?style=for-the-badge" alt="Admin" />
</p>

A modular, password-protected Command Prompt administrative and IT Helpdesk toolkit for Windows. **KyuTools** consolidates system diagnostics, routine maintenance, performance tuning, network optimization, security auditing, and remote troubleshooting into a single terminal dashboard.

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Password Gate](#password-gate)
- [Module Breakdown](#module-breakdown)
  - [1. Windows Activation and License](#1-windows-activation-and-license)
  - [2. Network and Internet Optimizer](#2-network-and-internet-optimizer)
  - [3. System Maintenance and Diagnostics](#3-system-maintenance-and-diagnostics)
  - [4. System Information Viewer](#4-system-information-viewer)
  - [5. Privacy and Telemetry Control](#5-privacy-and-telemetry-control)
  - [6. Performance Tweaks](#6-performance-tweaks)
  - [7. File and Disk Utilities](#7-file-and-disk-utilities)
  - [8. Printer and Device Sharing](#8-printer-and-device-sharing)
  - [9. IT Helpdesk & Quick Fixes](#9-it-helpdesk--quick-fixes)
  - [10. Remote Management & Access](#10-remote-management--access)
  - [11. Security and Intrusion Audit](#11-security-and-intrusion-audit)
  - [12. Windows All in One Utilities](#12-windows-all-in-one-utilities)
- [Project Structure](#project-structure)
- [Authors & Contributors](#authors--contributors)
- [Disclaimer](#disclaimer)

---

## Overview

KyuTools was built to help technicians, system administrators, and power users troubleshoot and optimize Windows workstations without needing third-party GUI software installations. It runs directly via standard Windows scripting engines (`cmd.exe` and `powershell.exe`) with native command-line utilities.

### Key Highlights
- **Self-Elevating Execution**: Verifies administrative permissions at startup and prompts UAC elevation automatically if required.
- **Console Security Gate**: Masked, invisible password input protects unauthorized interactive usage.
- **Modernized Windows 11 Support**: Replaces deprecated `wmic` calls with PowerShell CIM cmdlets (`Get-CimInstance`) for long-term compatibility.
- **Zero Third-Party Dependencies**: Uses native Windows tools (`sfc`, `dism`, `netsh`, `ipconfig`, `slmgr`, `powercfg`, `wevtutil`, and PowerShell).

---

## Getting Started

### Prerequisites
- **Operating System**: Windows 10 or Windows 11 (64-bit recommended)
- **Privileges**: Administrator rights
- **Shell**: PowerShell 5.1 or later (pre-installed on Windows 10/11)

### How to Run
1. Clone or download this repository onto the target Windows computer.
2. Right-click [`KyuTools.bat`](KyuTools.bat) and choose **Run as administrator** (or double-click; it will auto-request elevation).
3. Enter the security gate password when prompted.

### Password Gate
Input characters are hidden from the console display during entry for security.

- **Default Password**: `kyu04`
- **Location**: Defined in [`modules/pass.ps1`](modules/pass.ps1) (line 27). You can customize the password string inside this file.

---

## Module Breakdown

### 1. Windows Activation and License
Located in [`modules/activation.bat`](modules/activation.bat):
- **Activation Status Check**: Checks license expiration and grace periods via `slmgr.vbs /xpr` and `/dli`.
- **License Type Identification**: Inspects Windows edition, build number, serial number, and license channel (Retail, OEM, Volume).
- **Product Key Entry**: Installs product keys (`slmgr /ipk`) and attempts online activation (`slmgr /ato`).
- **Office Permanent Activation**: Integrates Microsoft Activation Scripts (MAS) Ohook method for Microsoft Office (`irm https://get.activated.win | iex`).
- **Trial Rearm**: Resets evaluation periods using `slmgr.vbs /rearm`.
- **Error Resolvers**: Automated repairs for common activation errors `0xC004F074` (KMS unavailable) and `0x8007007B` (invalid key format).
- **Detailed Diagnostics**: Displays full license details via `slmgr.vbs /dlv`.

### 2. Network and Internet Optimizer
Located in [`modules/network.bat`](modules/network.bat):
- **Full Network Reset**: Executes a complete 7-step network stack overhaul:
  1. DNS cache flush
  2. IP release
  3. Winsock catalog reset
  4. TCP/IP stack reset
  5. IPv4 and IPv6 stack reset
  6. Windows Firewall policy reset
  7. IP renewal via DHCP
- **DNS Speed Benchmark**: Measures round-trip ping latency across Google (8.8.8.8), Cloudflare (1.1.1.1), Quad9 (9.9.9.9), and OpenDNS (208.67.222.222).
- **DNS Server Switcher**: Quickly applies DNS presets (Google, Cloudflare, Quad9, OpenDNS, or custom IPs) directly to the active network interface.
- **Protocol Management**: Enable or disable IPv6 components and Teredo tunneling.
- **Connection Viewer & Speed Check**: Lists active listening and established sockets (`netstat`) and launches Fast.com speed testing.

### 3. System Maintenance and Diagnostics
Located in [`modules/maintenance.bat`](modules/maintenance.bat):
- **System File Integrity**: System File Checker (`sfc /scannow`).
- **Deployment Image Servicing**: DISM image health checks (`/CheckHealth`, `/ScanHealth`) and online component repair (`/RestoreHealth`).
- **Combined Repair**: Automated multi-stage repair pipeline running DISM repairs followed by an SFC scan.
- **Junk & Cache Cleanup**: Clears user temp folders, `%windir%\Temp`, Prefetch files, Recent file shortcuts, and Google Chrome / Microsoft Edge browser caches.
- **Windows Update Repair**: Stops update services, purges corrupted cache files in `SoftwareDistribution\Download` and `catroot2`, and restarts update services.
- **Storage Diagnostics**: Disk S.M.A.R.T. health checks via `Win32_DiskDrive`, read-only `CHKDSK`, or scheduled full disk repairs on reboot.
- **Memory Testing & Event Logs**: Schedules Windows Memory Diagnostics (`mdsched`), views the last 20 system error events, or wipes all Windows Event Logs.

### 4. System Information Viewer
Located in [`modules/sysinfo.bat`](modules/sysinfo.bat):
- **Hardware Inventory**: Queries detailed processor clock speeds and core counts, RAM physical sticks with vendor and frequency, GPU adapters and VRAM, and storage volumes.
- **Battery Health**: Generates an HTML battery health and capacity history report (`powercfg /batteryreport`) saved to the Desktop.
- **Processes & Autostart**: Displays active processes (`tasklist`) and queries registry Run keys (`HKCU` and `HKLM`) for startup applications.
- **Consolidated Export**: Exports a full diagnostic system summary to `KyuTools_Report.txt` on the current user's Desktop.

### 5. Privacy and Telemetry Control
Located in [`modules/privacy.bat`](modules/privacy.bat):
- **Disable Telemetry**: Disables `AllowTelemetry` group policies and disables background tracking services (`DiagTrack`, `dmwappushservice`).
- **Disable Cortana & Web Search**: Prevents web searches from the Windows taskbar search box and disables Cortana policies.
- **Advertising & Activity Tracking**: Disables Windows Advertising ID, Activity Feed / Timeline tracking, and location sensors.
- **Hosts File Endpoint Blocker**: Appends known Microsoft telemetry collection hostnames directly to `C:\Windows\System32\drivers\etc\hosts` mapped to `0.0.0.0`.
- **Default Restoration**: Reverts privacy and telemetry tweaks back to Windows default settings.

### 6. Performance Tweaks
Located in [`modules/performance.bat`](modules/performance.bat):
- **Power Schemes**: Unlocks and activates the High Performance power plan or the hidden Ultimate Performance power plan (`e9a42b02-d5df-448d-aa00-03f14749eb61`).
- **UI Responsiveness**: Minimizes window animation delays and eliminates the default Windows startup delay.
- **Memory Optimization**: Clears standby memory via .NET garbage collection routines.
- **Background Service Tuning**: Disables Windows Search indexing and SysMain (Superfetch).
- **Gaming Optimizations**: Disables Xbox Game Bar / Game DVR background recording, enables Windows Game Mode, and toggles Hardware-Accelerated GPU Scheduling (HAGS).

### 7. File and Disk Utilities
Located in [`modules/diskutils.bat`](modules/diskutils.bat):
- **Disk Usage & Drive Breakdown**: Summarizes free space and capacity for all attached partitions.
- **Heavy File Scanner**: Recursively scans all connected drives and lists the top 20 largest files with calculated sizes in megabytes.
- **NTFS Permissions**: Takes ownership (`takeown`) and grants full permissions (`icacls`) to the current user for locked files or folders.
- **Hidden Files Management**: Toggles visibility of hidden and protected operating system files in Windows Explorer, and recursively scans drives for hidden files.
- **Checksum Verification**: Calculates cryptographic hashes (MD5, SHA1, SHA256) for any specified file using `certutil`.
- **Symbolic Links & CBS Logs**: Creates directory or file symlinks (`mklink`), opens Disk Management (`diskmgmt.msc`), and reads the last 50 lines of `CBS.log`.

### 8. Printer and Device Sharing
Located in [`modules/printer.bat`](modules/printer.bat):
- **Network Discovery & Sharing**: Opens Windows Firewall rules for Network Discovery and File & Printer Sharing.
- **Printer Inventory & Sharing**: Queries installed printers via PowerShell `Get-Printer` and configures network share names.
- **Print Spooler Reset**: Stops and restarts the Windows Print Spooler service (`spooler`) to clear stuck or unresponsive print queues.

### 9. IT Helpdesk & Quick Fixes
Located in [`modules/ithelpdesk.bat`](modules/ithelpdesk.bat):
- **Direct BIOS / UEFI Reboot**: Restarts the workstation directly into UEFI/BIOS firmware settings (`shutdown /r /fw /t 0`).
- **Explorer Reload**: Terminates and restarts `explorer.exe` to recover from frozen taskbars and black screens.
- **Group Policy Repair**: Deletes local cached Group Policy folders and forces an immediate policy refresh (`gpupdate /force`).
- **Safe Mode Toggle**: Sets the boot configuration to minimal Safe Mode (`bcdedit /set {current} safeboot minimal`) or removes the flag to resume normal boot.
- **Modern App Repair**: Re-registers all default Windows AppX packages and Start Menu applications.

### 10. Remote Management & Access
Located in [`modules/remote.bat`](modules/remote.bat):
- **Remote Desktop Client**: Launches RDP (`mstsc.exe`) or Windows Quick Assist for end-user remote support.
- **Host Configuration**: Enables incoming Remote Desktop connections on the local computer and configures firewall rules.
- **Network Subnet Discovery**: ARP-based scanner that detects active devices on the local subnet, attempts reverse DNS hostname resolution, and checks logged-in usernames via ADSI and `quser`.
- **Remote Administration**: Opens remote Computer Management consoles (`compmgmt.msc /computer:\\<target>`), administrative hidden shares (`\\<target>\c$`), and the remote shutdown GUI (`shutdown -i`).

### 11. Security and Intrusion Audit
Located in [`modules/security.bat`](modules/security.bat):
- **Active Connections with Process IDs**: Runs `netstat -anob` to identify listening and established sockets mapped to owning processes.
- **Logon Audit**: Queries the Windows Security event log for recent successful logon events (Event ID 4624).
- **RDP Session Audit**: Queries the TerminalServices-LocalSessionManager log for incoming Remote Desktop connections (Event ID 1149).
- **Recent Executable Scan**: Scans `C:\Users` and `C:\ProgramData` for `.exe`, `.bat`, `.ps1`, and `.vbs` files created or modified in the last 24 hours.
- **USB Device Connection History**: Queries the `USBSTOR` registry keys to inspect previously connected USB storage devices.
- **Autostart Audit**: Checks `Run` keys in `HKLM` and `HKCU` for suspicious persistence entries.
- **Defender Threats**: Displays recent Windows Defender threat detections via `Get-MpThreatDetection`.

### 12. Windows All in One Utilities
Located in [`modules/allinone.bat`](modules/allinone.bat):
- Integrates the **Chris Titus Tech Windows Utility (WinUtil)**, an open-source toolbox providing automated program installations, debloat options, system tweaks, and Windows update configuration.
- Executes with Administrator privileges in PowerShell:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"
  ```

---

## Project Structure

```
IT-Stuffs/
├── KyuTools.bat            # Main entrypoint, admin elevation, and navigation menu
├── fix_wmic.ps1            # Maintenance script updating deprecated WMIC calls to CIM
├── README.md               # Project documentation and feature reference
└── modules/
    ├── pass.ps1            # Keystroke-masked password gate
    ├── activation.bat      # Windows and Office activation utilities
    ├── network.bat         # Network stack optimizer, DNS switcher, and latency checks
    ├── maintenance.bat     # SFC, DISM, cache cleaners, CHKDSK, event log tools
    ├── sysinfo.bat         # Hardware diagnostics and desktop report generator
    ├── privacy.bat         # Telemetry, Cortana, and host blocking tools
    ├── performance.bat     # Power plans, RAM flush, and gaming optimizations
    ├── diskutils.bat       # Heavy file finder, ownership tools, and hash checker
    ├── printer.bat         # Printer sharing and print spooler reset
    ├── ithelpdesk.bat      # UEFI reboot, explorer fixes, GPO reset, Safe Mode
    ├── remote.bat          # RDP, hidden shares, subnet ARP scanner, remote MMC
    ├── security.bat        # Logon audits, USB history, Defender threat inspection
    └── allinone.bat        # Chris Titus Tech WinUtil launcher
```

---

## Authors & Contributors

- **Creator & Lead Developer**: [**Kyu**](https://github.com/mong-g) ([@mong-g](https://github.com/mong-g))
- **Contributor**: [**themarneilx**](https://github.com/themarneilx) ([@themarneilx](https://github.com/themarneilx))

---

## Disclaimer

KyuTools provides direct access to administrative Windows utilities, registry modifications, policy alterations, and network resets. Use these tools responsibly. Always test optimizations and registry changes in appropriate environments prior to deploying across production systems.
