# =============================================================
#  grassmeter - make-package.ps1
#  Builds a distributable .rmskin package from source
#  Usage: Right-click -> Run with PowerShell
#         or: powershell -ExecutionPolicy Bypass -File make-package.ps1
# =============================================================

$ErrorActionPreference = 'Stop'

$root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$skinName = 'grassmeter'

# Read version from RMSKIN.ini
$version = '0.0.0'
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $root 'RMSKIN.ini'))) {
    if ($line -match '^Version\s*=\s*(.+)$') { $version = $Matches[1].Trim(); break }
}

$outputPath = Join-Path $root "$skinName-$version.rmskin"

Write-Host "=== grassmeter package builder ===" -ForegroundColor Cyan
Write-Host "Version : $version"
Write-Host "Output  : $outputPath"
Write-Host ""

# ------------------------------------------------------------------
# Exclude list (relative paths / patterns to skip from Skins/ entries)
# ------------------------------------------------------------------
$excludeNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    '.git', '.gitignore', '.claude',
    'HISTORY.md', 'README.pdf',
    'create_issues.ps1',
    'image.png', 'test1.png',
    'make-package.ps1'
) | ForEach-Object { $excludeNames.Add($_) | Out-Null }

$excludePatterns = @('*.rmskin', 'debug*.log', '*.tmp')

function Should-Exclude([string]$relPath) {
    # Skip anything inside .git or .claude
    if ($relPath -match '^\.git[\\/]'    -or $relPath -eq '.git')    { return $true }
    if ($relPath -match '^\.claude[\\/]' -or $relPath -eq '.claude') { return $true }
    $leaf = Split-Path $relPath -Leaf
    if ($excludeNames.Contains($leaf))                                { return $true }
    foreach ($pat in $excludePatterns) {
        if ($leaf -like $pat)                                         { return $true }
    }
    return $false
}

# ------------------------------------------------------------------
# Prepare placeholder Settings.inc for bundling
# ------------------------------------------------------------------
$settingsInc     = Join-Path $root 'Settings.inc'
$settingsExample = Join-Path $root 'Settings.inc.example'
$createdTemp     = $false

if (-not (Test-Path $settingsInc)) {
    if (-not (Test-Path $settingsExample)) {
        Write-Error "Settings.inc.example not found. Cannot build package."
        exit 1
    }
    Copy-Item $settingsExample $settingsInc
    $createdTemp = $true
    Write-Host "Created placeholder Settings.inc from example" -ForegroundColor Yellow
} else {
    Write-Host "Using existing Settings.inc (credentials will NOT be bundled — replaced with placeholders)" -ForegroundColor Yellow
    # Read existing but replace token/username with placeholders so we never ship real creds
    $raw = [System.IO.File]::ReadAllText($settingsInc, [System.Text.UTF8Encoding]::new($true))
    $raw = $raw -replace '(?m)^GitHubToken=(?!ghp_x{20})(.+)$', 'GitHubToken=ghp_xxxxxxxxxxxxxxxxxxxx'
    $raw = $raw -replace '(?m)^GitHubUsername=(?!your_)(\S+)$', 'GitHubUsername=your_github_username'
    $tempSafe = $settingsInc + '.pkg_tmp'
    [System.IO.File]::WriteAllText($tempSafe, $raw, [System.Text.UTF8Encoding]::new($true))
    $settingsInc = $tempSafe
    $createdTemp = $true
}

# ------------------------------------------------------------------
# Build ZIP (.rmskin)
# ------------------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

try {
    $zip = [System.IO.Compression.ZipFile]::Open($outputPath, 'Create')

    # 1. RMSKIN.ini at ZIP root
    $rmSkinIni = Join-Path $root 'RMSKIN.ini'
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $rmSkinIni, 'RMSKIN.ini') | Out-Null
    Write-Host "  + RMSKIN.ini"

    # 2. All skin files under Skins\grassmeter\
    $allFiles = Get-ChildItem $root -Recurse -File

    foreach ($file in $allFiles) {
        $rel = $file.FullName.Substring($root.Length).TrimStart('\', '/')

        if (Should-Exclude $rel) { continue }
        # RMSKIN.ini is already added at root; skip the in-folder copy
        if ($rel -eq 'RMSKIN.ini') { continue }

        # If this is the temp safe settings, use it as Settings.inc
        if ($file.FullName -eq $settingsInc) {
            $entryName = "Skins\$skinName\Settings.inc"
        } else {
            $entryName = "Skins\$skinName\$rel"
        }

        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName) | Out-Null
        Write-Host "  + $entryName"
    }

    # Make sure Settings.inc is in the package (in case it was a .pkg_tmp override)
    # already added above via the $settingsInc path

    $zip.Dispose()

    # ------------------------------------------------------------------
    # Append RMSKIN footer (required by Rainmeter installer for validation)
    # Struct (16 bytes total, matches DialogInstall.h PackageFooter):
    #   [8 bytes] int64  size  = byte offset of footer from file start (= zip size)
    #   [1 byte]  uint8  flags = 0
    #   [7 bytes] char[] key   = "RMSKIN\0"
    # ------------------------------------------------------------------
    $stream = [System.IO.File]::Open($outputPath, 'Append', 'Write')
    $footerOffset = $stream.Position   # = zip file size, i.e. where footer starts
    $writer = New-Object System.IO.BinaryWriter($stream)
    $writer.Write([Int64]$footerOffset)
    $writer.Write([Byte]0)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RMSKIN`0"))
    $writer.Close()
    $stream.Close()

    Write-Host ""
    Write-Host "Done: $outputPath" -ForegroundColor Green

} catch {
    if ($null -ne $zip) { $zip.Dispose() }
    if (Test-Path $outputPath) { Remove-Item $outputPath -Force }
    Write-Error "Package build failed: $_"
    exit 1

} finally {
    # Clean up temp file
    if ($createdTemp -and (Test-Path $settingsInc)) {
        Remove-Item $settingsInc -Force
        Write-Host "Removed temporary Settings.inc" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Installation flow for users:" -ForegroundColor Cyan
Write-Host "  1. Double-click $skinName-$version.rmskin to install"
Write-Host "  2. Widget appears showing 'Setup required'"
Write-Host "  3. Click the gear icon -> enter GitHub Token -> Save & Refresh"
