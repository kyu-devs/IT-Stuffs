# Working on KyuTools

Read `docs/PROJECT_CONTEXT.md` and `docs/VALIDATION.md` before changing repair
behavior. The entry point is `KyuTools.bat`; Batch modules retain navigation,
with checked higher-impact operations in `modules/system_tools.ps1` and printer
operations in `modules/printer_core.ps1` / `modules/printer_tools.ps1`.

Keep Windows PowerShell 5.1 compatibility and avoid adding package dependencies.
Libraries must be safe to dot-source without launching menus or modifying the
machine. Use named parameters/literal paths, check native exit codes, and verify
the requested postcondition. Record cancellation, failure, and uncertainty
accurately. A submitted job is not verified physical output.

Preserve existing working-copy changes. Test Windows mutation boundaries with
controlled doubles rather than running repairs against the development PC.
Do not weaken printer authentication, SMB signing, RPC privacy, or driver
installation policy as a generic repair. Keep queue clearing separate from
connection attempts and retain driver packages.

Run both checks after source changes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\validate.ps1
```

PowerShell files use UTF-8 with BOM for Windows PowerShell 5.1. Batch files use
UTF-8 without BOM and CRLF line endings. Keep documentation consistent with the
actual menu behavior and distinguish automated checks from hardware acceptance.
