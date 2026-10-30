# Toolkit reliability upgrade

The user authorized implementation using engineering judgment and opted out of
further design questions. Keep the Batch menus and Windows PowerShell 5.1 support.
Preserve existing working-copy changes; implement in place, without committing,
running repairs on the development PC, or installing dependencies.

Improve all 14 areas with the most extensive work in printer/device sharing.
Use shared checked native-command execution, operation logs, explicit repair
confirmation, input validation, verified outcomes, and read-only diagnostics.
Printer connections must preserve SMB signing, RPC privacy, administrator-only
driver installation, and authenticated access. Never silently enable Guest,
SMB1, anonymous access, or clear every user's queue as a connection side effect.
Provide UNC and direct TCP/IP workflows, driver guidance, scoped queue clearing,
host/client diagnostics, default selection, optional test page, and error advice.

Fix keyword matching, repair-step status, unsupported commands, misleading
hardware conclusions, license verification, Office deployment, power-plan GUIDs,
RDP capability checks, event channels, account lockout handling, and report paths.
Retain lower-impact existing utilities. Replace high-impact actions with checked
PowerShell operations behind existing menu choices; preserve the network scanner
while fixing PowerShell 5.1 compatibility and incorrect identity assumptions.

Alternatives considered: rebuilding the complete application would disrupt the
existing workflow; patching printer errors alone would miss confirmed defects
elsewhere. Shared helpers plus targeted module upgrades best fit the request.

Automated acceptance: dependency-free Windows PowerShell tests for pure logic,
native failures, injected Windows service/print boundaries, syntax, and Batch
dispatch integrity. Manual acceptance: Windows host/client, installed drivers,
physical printer, and controlled VM repair tests. Never equate tests with a
universal repair guarantee or physical print verification.
