# ONYX IT DEPARTMENT TECH TOOLS - Password Gate
# Handles completely invisible password input (no stars or characters shown)

$password = ""
Write-Host "                           PASSWORD : " -NoNewline -ForegroundColor Green

while ($true) {
    # Read a key without printing it to the console ($true)
    $key = [System.Console]::ReadKey($true)
    
    if ($key.Key -eq 'Enter') {
        Write-Host "" # Print newline on enter
        break
    } elseif ($key.Key -eq 'Backspace') {
        if ($password.Length -gt 0) {
            $password = $password.Substring(0, $password.Length - 1)
        }
    } elseif ($key.Key -eq 'Escape') {
        $password = ""
    } elseif ($key.KeyChar -ne "`0") {
        # Append typed character
        $password += $key.KeyChar
    }
}

# Verify
if ($password -eq "kyu04") {
    exit 0
} else {
    exit 1
}
