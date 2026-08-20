# Studio Crow device-test helpers: dump screen text + tap by text/label.
# Usage: powershell -File tool/tap.ps1 -Action dump | -Action tap -Text "Add Course" [-Index 0]
param(
    [string]$Action = 'dump',
    [string]$Text = '',
    [int]$Index = 0
)
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

function Get-UiXml {
    & $adb -s 65201XEA30CA63 shell uiautomator dump /sdcard/ui.xml 2>$null | Out-Null
    & $adb -s 65201XEA30CA63 shell cat /sdcard/ui.xml
}

if ($Action -eq 'dump') {
    $xml = Get-UiXml
    # Extract text nodes with bounds
    [regex]::Matches($xml, 'text="([^"]+)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"') |
        ForEach-Object {
            $t = $_.Groups[1].Value
            if ($t) { "$($_.Groups[2].Value),$($_.Groups[3].Value),$($_.Groups[4].Value),$($_.Groups[5].Value) | $t" }
        }
    Write-Output "---END---"
} elseif ($Action -eq 'tap') {
    $xml = Get-UiXml
    $matches = [regex]::Matches($xml, 'text="([^"]+)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
    $found = @()
    foreach ($m in $matches) {
        if ($m.Groups[1].Value -like "*$Text*") {
            $x = ([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2
            $y = ([int]$m.Groups[3].Value + [int]$m.Groups[5].Value) / 2
            $found += , @($x, $y, $m.Groups[1].Value)
        }
    }
    if ($found.Count -eq 0) { Write-Output "NOT_FOUND: $Text"; exit 1 }
    $target = $found[$Index]
    Write-Output "TAP $($target[2]) @ $($target[0]),$($target[1])"
    & $adb -s 65201XEA30CA63 shell input tap $target[0] $target[1]
    exit 0
}
