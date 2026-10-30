# Structural validation only: no toolkit entry points or repairs are executed.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$failures=[Collections.Generic.List[string]]::new()
$powershellFiles=@(Get-ChildItem -LiteralPath $root -Filter *.ps1 -File)+@(Get-ChildItem -LiteralPath (Join-Path $root 'modules') -Filter *.ps1 -File)+@(Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.ps1 -File)
foreach ($file in $powershellFiles) {
    $tokens=$null;$issues=$null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$issues)
    foreach ($issue in $issues) { $failures.Add("$($file.Name):$($issue.Extent.StartLineNumber): $($issue.Message)") }
}
$tokens=$null;$issues=$null
$systemAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'modules\system_tools.ps1'),[ref]$tokens,[ref]$issues)
$dispatch=$systemAst.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-KyuSystemAction'},$true)
$branch=$dispatch.Find({param($n) $n -is [Management.Automation.Language.SwitchStatementAst]},$true)
$patterns=@($branch.Clauses | ForEach-Object { $_.Item1.Value })
$batchFiles=@(Get-Item -LiteralPath (Join-Path $root 'KyuTools.bat'))+@(Get-ChildItem -LiteralPath (Join-Path $root 'modules') -Filter *.bat -File)
$routes=0
foreach ($file in $batchFiles) {
    $content=[IO.File]::ReadAllText($file.FullName)
    $labels=@([regex]::Matches($content,'(?m)^:([^:\r\n]+)\r?$') | ForEach-Object { $_.Groups[1].Value.Trim() })
    foreach ($match in [regex]::Matches($content,'(?im)\bgoto\s+:?([A-Za-z_][A-Za-z0-9_]*)')) {
        $target=$match.Groups[1].Value
        if ($target -ne 'EOF' -and $target -notin $labels) { $failures.Add("$($file.Name): missing label $target") }
    }
    foreach ($match in [regex]::Matches($content,'(?im)%~dp0([^"%\r\n]+\.ps1)')) {
        if (-not (Test-Path -LiteralPath (Join-Path $file.DirectoryName $match.Groups[1].Value) -PathType Leaf)) { $failures.Add("$($file.Name): missing script $($match.Groups[1].Value)") }
    }
    foreach ($match in [regex]::Matches($content,'(?im)system_tools\.ps1"\s+-Action\s+([A-Za-z0-9]+)')) {
        $actionName=$match.Groups[1].Value; $routes++
        if (-not @($patterns | Where-Object { $actionName -match $_ }).Count) { $failures.Add("$($file.Name): action $actionName has no dispatcher branch") }
    }
    $bytes=[IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { $failures.Add("$($file.Name): Batch files must not start with a UTF-8 BOM") }
}
if ($failures.Count) { $failures | ForEach-Object { Write-Host $_ -ForegroundColor Red }; exit 1 }
Write-Host ("Validated {0} PowerShell files, {1} Batch menus, {2} system-action routes; zero errors." -f $powershellFiles.Count,$batchFiles.Count,$routes)
