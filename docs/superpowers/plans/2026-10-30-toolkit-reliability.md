# Toolkit Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve all 14 toolkit areas, especially printer sharing, with checked results and regression coverage.
**Architecture:** Preserve Batch navigation. Add side-effect-free shared PowerShell libraries, printer operations, and a checked system-action dispatcher.
**Tech Stack:** cmd.exe, Windows PowerShell 5.1, built-in Windows tools; dependency-free tests.
**Spec:** docs/superpowers/specs/2026-10-30-toolkit-reliability-design.md

## Global Constraints

- Preserve existing working-copy changes; implement in place without commits.
- Do not execute system repairs or downloads during tests.
- Keep authenticated printer sharing and existing Windows security protections.
- Report failure, skipped steps, and unverified outcomes honestly.

## Review Focus

- Invalid UNC names or shell metacharacters cannot execute commands.
- Two hosts sharing the same printer name must remain distinguishable.
- Failed services, refused connections, and driver errors must not report success.
- Cancellation and exceptions must not leave stopped services or delete unrelated files.
- PS 5.1 and redirected Desktop paths must work without optional modules.

### Task 1: Shared operation helpers and tests
Files: modules/common.ps1; tests/run.ps1.
Interfaces: Invoke-KyuNative(FilePath, Arguments, SuccessCodes); Test-KyuHostName;
Test-KyuTcpPort; Get-KyuDesktop; Confirm-KyuAction; Write-KyuLog.
- [x] Write regression tests for native nonzero exits, invalid names, and TCP refusal.
- [x] Watch failures, implement helpers, and rerun tests.

### Task 2: Printer repair workflow
Files: modules/printer_core.ps1, modules/printer_tools.ps1,
modules/connect_printer.ps1, modules/printer.bat; tests/run.ps1.
Interfaces: Resolve-KyuPrinterTarget, Format-PrinterError,
Connect-PrinterTarget, Restart-KyuSpooler, Get-KyuPrinterDiagnostics.
- [x] Test UNC resolution/ambiguity, exact error codes, verified connection, spooler failure recovery.
- [x] Implement read-only discovery, authenticated host setup, scoped repair,
  direct TCP/IP setup, logs, drivers, default selection, and optional test page.
- [x] Run tests with all external mutations mocked.

### Task 3: Checked actions across menus 1-13
Files: modules/system_tools.ps1, modules/*.bat, launch.ps1.
Interfaces: Invoke-KyuSystemAction(Action); Get-KyuOfficeConfiguration;
Get-KyuLicenseAdvice; Get-KyuMemorySummary.
- [x] Test Office XML/product mapping, key validation, plan GUIDs, backup path guards,
  failure handling, reports, and account/remote capability branches.
- [x] Route consequential existing menu actions through checked operations;
  retain diagnostics and utilities that do not need replacement.
- [x] Verify syntax and menu-to-action routes.

### Task 4: Problem solver and scanner
Files: modules/troubleshoot.ps1, modules/network_scan.ps1; tests/run.ps1.
Interfaces: Find-Problem(ProblemText), Run-Step(...), existing scanner output.
- [x] Reproduce category collisions and supported-keyword failures.
- [x] Fix matcher/status and reuse printer helpers; check native exits, remove
  unsupported options and hardware-failure claims, preserve scanner functionality.
- [x] Run full regression suite.

### Task 5: Documentation and independent review
Files: README.md, docs/PROJECT_CONTEXT.md, docs/VALIDATION.md.
- [x] Record implemented behavior, test evidence, limitations, and manual acceptance steps.
- [x] Run regression suite, PowerShell parsing, Batch route validation, whitespace checks.
- [x] Obtain fresh-context code review and fix consequential findings with tests.
