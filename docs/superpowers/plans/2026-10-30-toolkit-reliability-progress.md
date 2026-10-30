# Execution ledger: 2026-10-30-toolkit-reliability.md

Ruling: implement in the current working copy on main without git mutations;
the user explicitly asked to update this folder and to proceed using judgment.
Pre-existing source edits are part of the input, not disposable work.

Ruling: execute inline and use one fresh reviewer at the end. No implementation
delegation or dependencies are needed. The user's opt-out covers further design
and execution-method questions.

Pre-flight: Tasks 2-4 consume the common helpers from Task 1; callers will use
named parameters and error-terminating operations. Printer tools are separate
from the system dispatcher so dot-sourcing libraries never launches a menu.

Baseline: five module PowerShell files parse; no test suite existed. Isolated
Find-Problem('printer offline') returns no match; renaming Input to ProblemText
restores matching. Error 1260 is misclassified as 126. No repairs executed.

Task 1: complete. Shared helpers and controlled native/host/TCP/path tests.
Task 2: complete. Expanded printer menu, retained protections, scoped cleanup,
diagnostics, exact error codes, connection verification, and explicit restoration.
Task 3: complete. Eighty checked Batch routes; signed Office deployment,
licensing checks, servicing/network/preferences/files/remote/recovery changes.
Task 4: complete. Matcher specificity, explicit outcome accounting, checked
recipes, current troubleshooters, bounded PS 5.1 scanner and source-labeled hints.
Task 5: complete. README/context/AGENTS/validation updated; independent review
findings addressed; 38 tests and structural validation pass. Hardware acceptance
is documented as outstanding rather than being represented as verified.

Ruling: unsupported blanket optimizations/security downgrades and external
activation shortcuts are replaced by supported diagnostics/licensing guidance;
retaining them as automatic fixes conflicts with effective, dependable repair.

Ruling: refuse nonstandard spool locations and ancestor reparse paths rather
than guessing cleanup/copy targets. Refuse forced service stops with unexpected
dependents rather than stopping components the repair cannot restore.

Review: no Critical findings. Fixed five Important findings: buffered
interactive output, service dependencies/audio order, backup ancestor-junction
aliasing, custom spool directories, and scanner identity provenance. Added
regressions for each noninteractive repair case; interactive smoke passed.

Validation correction: an AST-based bulk edit used hashtable sorting incorrectly;
parsing caught it. Reconstructed only this task's edits to troubleshoot.ps1,
sorted typed offsets descending, and required successful parsing before saving.
The final recipe changes and complete suite were then verified.
