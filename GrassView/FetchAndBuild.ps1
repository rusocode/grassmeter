# =============================================================
#  GitHub Grass for Rainmeter
#  FetchAndBuild.ps1
#  Fetches GitHub contribution data and generates GrassView.ini
# =============================================================
param(
    [string]$SkinPath     = '',
    [string]$OutputIni    = '',
    [int]$WeeksOverride   = 0,
    [switch]$YearMode
)

if (-not $SkinPath)  { $SkinPath  = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputIni) { $OutputIni = Join-Path $SkinPath 'GrassView.ini' }

$Log = Join-Path $SkinPath 'debug.log'
[System.IO.File]::WriteAllText($Log, '', [System.Text.UTF8Encoding]::new($false))
function L($m) {
    [System.IO.File]::AppendAllText($Log, "[$(Get-Date -f HH:mm:ss)] $m`r`n", [System.Text.UTF8Encoding]::new($false))
}
L '=== GitHub Grass v1.0 ==='

# ------------------------------------------------------------------
# Parse Settings.inc
# ------------------------------------------------------------------
$Username = ''; $Token = ''; $Weeks = 52; $CellSize = 11
$CellGap  = 2;  $Padding = 14; $Theme = 'Green'
$Repo1 = ''; $Repo2 = ''; $Repo3 = ''
$IsYearMode = $true

$sf = Join-Path (Split-Path $SkinPath -Parent) 'Settings.inc'
if (Test-Path $sf) {
    foreach ($line in [System.IO.File]::ReadAllLines($sf, [System.Text.UTF8Encoding]::new($true))) {
        if ($line -match '^GitHubUsername\s*=\s*(.+)$') { $Username = $Matches[1].Trim() }
        if ($line -match '^GitHubToken\s*=\s*(.+)$')    { $Token    = $Matches[1].Trim() }
        if ($line -match '^WeeksToShow\s*=\s*(\d+)')    { $Weeks    = [int]$Matches[1] }
        if ($line -match '^CellSize\s*=\s*(\d+)')       { $CellSize = [int]$Matches[1] }
        if ($line -match '^CellGap\s*=\s*(\d+)')        { $CellGap  = [int]$Matches[1] }
        if ($line -match '^Padding\s*=\s*(\d+)')        { $Padding  = [int]$Matches[1] }
        if ($line -match '^ColorTheme\s*=\s*(.+)$')     { $Theme    = $Matches[1].Trim() }
        if ($line -match '^Repo1\s*=\s*(.+)$')          { $Repo1    = $Matches[1].Trim() }
        if ($line -match '^Repo2\s*=\s*(.+)$')          { $Repo2    = $Matches[1].Trim() }
        if ($line -match '^Repo3\s*=\s*(.+)$')          { $Repo3    = $Matches[1].Trim() }
        if ($line -match '^YearMode\s*=\s*1')            { $IsYearMode = $true }
    }
    L 'Settings.inc loaded'
} else {
    L 'WARNING: Settings.inc not found, using defaults'
}
L "Username=$Username  Weeks=$Weeks  Theme=$Theme  CellSize=$CellSize"

# Apply WeeksOverride and persist to Settings.inc
if ($WeeksOverride -gt 0) {
    $Weeks = $WeeksOverride
    if (Test-Path $sf) {
        $sfc = [System.IO.File]::ReadAllText($sf, [System.Text.UTF8Encoding]::new($true))
        if ($sfc -match 'YearMode=') {
            $sfc = $sfc -replace 'YearMode=\d', 'YearMode=1'
        } else {
            $sfc = $sfc.TrimEnd() + "`r`nYearMode=1`r`n"
        }
        [System.IO.File]::WriteAllText($sf, $sfc, [System.Text.UTF8Encoding]::new($true))
    }
}

# Activar YearMode si se pasó el switch
if ($YearMode) { $IsYearMode = $true }

# Cualquier WeeksOverride explícito desactiva YearMode
if ($WeeksOverride -gt 0) { $IsYearMode = $false }

# Persistir YearMode en Settings.inc
if (Test-Path $sf) {
    $sfc = [System.IO.File]::ReadAllText($sf, [System.Text.UTF8Encoding]::new($true))
    $ymVal = if ($IsYearMode) { '1' } else { '0' }
    if ($sfc -match 'YearMode=') {
        $sfc = $sfc -replace 'YearMode=\d', "YearMode=$ymVal"
    } else {
        $sfc = $sfc.TrimEnd() + "`r`nYearMode=$ymVal`r`n"
    }
    [System.IO.File]::WriteAllText($sf, $sfc, [System.Text.UTF8Encoding]::new($true))
}
L "IsYearMode=$IsYearMode"

# Upstream improvement: stricter token validation
if ($Token -eq '' -or $Token -match '^ghp_x+$' -or $Token -eq 'ghp_your_token_here') { L 'ERROR: GitHubToken not set'; exit 1 }

# Auto-detect username from token if not configured in Settings.inc
if ($Username -eq '' -or $Username -eq 'your_username') {
    L 'GitHubUsername not set - auto-detecting from token...'
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $wc.Headers['Authorization'] = "Bearer $Token"
        $wc.Headers['User-Agent']    = 'Rainmeter-GitHubGrass/1.0'
        $me = ($wc.DownloadString('https://api.github.com/user')) | ConvertFrom-Json
        $Username = $me.login
        L "Auto-detected username: $Username"
        # Persist to Settings.inc so future runs are faster
        if (Test-Path $sf) {
            $sfc = [System.IO.File]::ReadAllText($sf, [System.Text.UTF8Encoding]::new($true))
            if ($sfc -match 'GitHubUsername=') {
                $sfc = $sfc -replace 'GitHubUsername=.*', "GitHubUsername=$Username"
            } else {
                $sfc = $sfc -replace 'GitHubToken=', "GitHubUsername=$Username`r`nGitHubToken="
            }
            [System.IO.File]::WriteAllText($sf, $sfc, [System.Text.UTF8Encoding]::new($true))
            L "Saved username to Settings.inc"
        }
    } catch {
        L ('Auto-detect username failed: ' + $_.Exception.Message)
        exit 1
    }
}

# ------------------------------------------------------------------
# Color themes
# ------------------------------------------------------------------
$cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='14,90,52,255'; $cL2='0,135,62,255'; $cL3='50,185,80,255'; $cL4='70,225,95,255'
if     ($Theme -eq 'Purple') { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='55,20,115,255'; $cL2='105,35,180,255'; $cL3='155,100,240,255'; $cL4='210,170,255,255' }
elseif ($Theme -eq 'Blue')   { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='15,45,85,255';  $cL2='15,80,190,255';  $cL3='40,125,245,255'; $cL4='100,180,255,255'  }
elseif ($Theme -eq 'Red')    { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='90,30,30,255';  $cL2='165,32,32,255';  $cL3='220,58,58,255';  $cL4='255,130,130,255' }
elseif ($Theme -eq 'Orange') { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='95,48,0,255';   $cL2='180,92,0,255';   $cL3='235,125,0,255';  $cL4='255,180,30,255'  }
elseif ($Theme -eq 'Pink')   { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='95,0,48,255';   $cL2='180,0,100,255';  $cL3='235,0,140,255';  $cL4='255,125,195,255' }
elseif ($Theme -eq 'Mono')   { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='55,55,55,255';  $cL2='100,100,100,255';$cL3='155,155,155,255';$cL4='210,210,210,255' }
elseif ($Theme -eq 'Mint')   { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='0,70,65,255';   $cL2='0,130,115,255';  $cL3='0,188,160,255';  $cL4='100,230,215,255' }
elseif ($Theme -eq 'Yellow') { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='100,88,0,255';  $cL2='180,158,0,255';  $cL3='225,200,0,255';  $cL4='255,240,0,255'   }
elseif ($Theme -eq 'Cyan')   { $cBG='13,17,23,240'; $cL0='33,38,46,255'; $cL1='0,65,95,255';   $cL2='0,130,180,255';  $cL3='0,200,238,255';  $cL4='60,235,255,255'  }
elseif ($Theme -eq 'Light')  { $cBG='245,247,250,240'; $cL0='235,237,240,255'; $cL1='155,233,168,255'; $cL2='64,196,99,255'; $cL3='48,161,78,255'; $cL4='33,110,57,255' }
L "Theme=$Theme  L0=[$cL0]  L4=[$cL4]"

# UI palette - adapts for light vs dark backgrounds
$isLight   = ($Theme -eq 'Light')
$cStroke   = if ($isLight) { '208,215,222,255' } else { '48,54,61,255' }
$cText     = if ($isLight) { '57,62,68,255'    } else { '139,148,158,255' }
$cTextDim  = if ($isLight) { '110,119,129,180' } else { '88,96,105,180' }
$cBtnAct   = if ($isLight) { '36,41,47,255'    } else { '220,220,220,255' }
$cBtnInact = if ($isLight) { '110,119,129,180' } else { '88,96,105,180' }
$cCellTip  = if ($isLight) { '80,90,100,180'   } else { '200,200,200,180' }

# ------------------------------------------------------------------
# GitHub GraphQL API - date range
# ------------------------------------------------------------------
$End = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

if ($IsYearMode) {
    $yr        = (Get-Date).Year
    $Start     = "$yr-01-01T00:00:00Z"
    $yearStart = [datetime]::new($yr, 1, 1)
    $yearEnd   = [datetime]::new($yr, 12, 31)
    # Domingo anterior (o igual) al 1 de enero
    $SD        = $yearStart.AddDays(-([int]$yearStart.DayOfWeek))
    # Sabado posterior (o igual) al 31 de diciembre
    $gridEndSat = $yearEnd.AddDays((6 - [int]$yearEnd.DayOfWeek) % 7)
    $Weeks     = [int](($gridEndSat - $SD).TotalDays / 7)
    L "YearMode: year=$yr  SD=$($SD.ToString('yyyy-MM-dd'))  Weeks=$Weeks"
} else {
    $Start    = (Get-Date).AddDays(-($Weeks * 7)).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $TodaySun = (Get-Date).Date.AddDays(-([int](Get-Date).DayOfWeek))
    $SD       = $TodaySun.AddDays(-(($Weeks - 1) * 7))
}

$Body  = '{"query":"query($login:String!,$from:DateTime!,$to:DateTime!){user(login:$login){contributionsCollection(from:$from,to:$to){contributionCalendar{totalContributions weeks{contributionDays{contributionCount date weekday}}}}}}","variables":{"login":"' + $Username + '","from":"' + $Start + '","to":"' + $End + '"}}'
$Headers = @{
    Authorization  = "Bearer $Token"
    'Content-Type' = 'application/json'
    'User-Agent'   = 'Rainmeter-GitHubGrass/1.0'
}

L 'Calling GitHub API...'
try {
    # Upstream improvement: TimeoutSec 30
    $R = Invoke-RestMethod -Uri 'https://api.github.com/graphql' -Method POST -Headers $Headers -Body $Body -TimeoutSec 30 -ErrorAction Stop
    if ($R.errors) { L ("GraphQL error: " + $R.errors[0].message); exit 1 }
    $Cal   = $R.data.user.contributionsCollection.contributionCalendar
    $Total = $Cal.totalContributions
    L "API OK  total=$Total"
} catch {
    L ("API failed: " + $_.Exception.Message)
    exit 1
}

# Build date->count map
$Map = @{}
$Max = 0
foreach ($w in $Cal.weeks) {
    foreach ($d in $w.contributionDays) {
        $Map[$d.date] = [int]$d.contributionCount
        if ([int]$d.contributionCount -gt $Max) { $Max = [int]$d.contributionCount }
    }
}
L "Max daily commits=$Max"

# ------------------------------------------------------------------
# Streak calculation
# ------------------------------------------------------------------
$todayStr = (Get-Date).Date.ToString('yyyy-MM-dd')

# Current streak: count consecutive days with contributions, backward from today
$curStreak = 0
$chkDate   = (Get-Date).Date
if (-not $Map.ContainsKey($todayStr) -or $Map[$todayStr] -eq 0) {
    $chkDate = $chkDate.AddDays(-1)
}
while ($true) {
    $ds = $chkDate.ToString('yyyy-MM-dd')
    if ($Map.ContainsKey($ds) -and $Map[$ds] -gt 0) {
        $curStreak++
        $chkDate = $chkDate.AddDays(-1)
    } else { break }
}

# Longest streak from all fetched data
$longestStreak = 0
$runStreak     = 0
foreach ($ds in ($Map.Keys | Sort-Object)) {
    if ($Map[$ds] -gt 0) {
        $runStreak++
        if ($runStreak -gt $longestStreak) { $longestStreak = $runStreak }
    } else { $runStreak = 0 }
}
L "Streak: current=$curStreak  best=$longestStreak"

# ------------------------------------------------------------------
# Star count for configured repos
# ------------------------------------------------------------------
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$TotalStars     = -1
$configuredRepos = @($Repo1, $Repo2, $Repo3) | Where-Object { $_ -ne '' }
if ($configuredRepos.Count -gt 0) {
    $TotalStars = 0
    foreach ($repo in $configuredRepos) {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Encoding = [System.Text.Encoding]::UTF8
            $wc.Headers['Authorization'] = "Bearer $Token"
            $wc.Headers['User-Agent']    = 'Rainmeter-GitHubGrass/1.0'
            $rd = ($wc.DownloadString('https://api.github.com/repos/' + $repo)) | ConvertFrom-Json
            $TotalStars += [int]$rd.stargazers_count
            L "Stars: $repo = $($rd.stargazers_count)"
        } catch {
            L ("Stars fetch failed ($repo): " + $_.Exception.Message)
            $TotalStars = -1
            break
        }
    }
}
L "TotalStars=$TotalStars"

# ------------------------------------------------------------------
# Layout calculations
# ------------------------------------------------------------------
$Step    = $CellSize + $CellGap
$DLW     = 28
$MonthH  = 22
$BtnRowH  = 26
$StreakH  = 22
$LegendH  = 24
$PBtnW   = 26
$GW      = $Weeks * $Step - $CellGap
$GH      = 7 * $Step - $CellGap
$ContentW = $GW
$WW      = $Padding * 2 + $DLW + $ContentW
$WH      = $Padding * 2 + $MonthH + $GH + $BtnRowH + $StreakH + $LegendH
$OX      = $Padding + $DLW
$OY      = $Padding + $MonthH

L "Widget size: ${WW}x${WH}"

# Build grid (col=week, row=weekday 0=Sun)
$Grid = @{}
$cur  = $SD
for ($c = 0; $c -lt $Weeks; $c++) {
    for ($r = 0; $r -lt 7; $r++) {
        $ds  = $cur.ToString('yyyy-MM-dd')
        $cnt = if ($Map.ContainsKey($ds)) { $Map[$ds] } else { 0 }
        $Grid["$c,$r"] = @{ date = $ds; count = $cnt; future = ($cur -gt (Get-Date)) }
        $cur = $cur.AddDays(1)
    }
}

# Month label positions
$MN = @('','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')
$ML = @{}
$PM = -1
for ($c = 0; $c -lt $Weeks; $c++) {
    $d = $Grid["$c,0"]
    if ($d) {
        $colDate = [datetime]$d.date
        # En YearMode, ignorar columnas de años anteriores (ej: dic 2025)
        if ($IsYearMode -and $colDate.Year -lt (Get-Date).Year) {
            # Forzar "Jan" en columna 0 aunque su domingo sea de 2025
            if ($c -eq 0) { $ML[0] = 'Jan'; $PM = 1 }
            continue
        }
        $m = [int]$colDate.Month
        if ($m -ne $PM) { $ML[$c] = $MN[$m]; $PM = $m }
    }
}

# ------------------------------------------------------------------
# Generate GrassView.ini
# ------------------------------------------------------------------
$lines = [System.Collections.Generic.List[string]]::new()
function W($s) { $lines.Add($s) }

W ("; GitHub Grass - Generated " + (Get-Date -f 'yyyy-MM-dd HH:mm'))
W "; DO NOT EDIT - regenerated by run.bat"
W ""
W "[Rainmeter]"
W "Update=30000"
W "AccurateText=1"
W ""
W "[Variables]"
W ("SkinFolder=" + $SkinPath)
W ""

# Background
W "[MeterBG]"
W "Meter=Shape"
W "X=0"
W "Y=0"
W ("Shape=Rectangle 0,0," + $WW + "," + $WH + ",8 | Fill Color " + $cBG + " | StrokeWidth 1 | Stroke Color " + $cStroke)
W ""

# Month labels
$mi = 0
foreach ($c in ($ML.Keys | Sort-Object { [int]$_ })) {
    $x = $OX + $c * $Step
    W "[MML$mi]"
    W "Meter=String"
    W "X=$x"
    W "Y=$Padding"
    W "W=40"
    W "H=$MonthH"
    W ("Text=" + $ML[$c])
    W "FontColor=$cText"
    W "FontSize=9"
    W "FontFace=Segoe UI"
    W "AntiAlias=1"
    W ""
    $mi++
}

# Day labels (Sun - Sat)
$DayNames = @('Sun','Mon','Tue','Wed','Thu','Fri','Sat')
for ($r = 0; $r -lt 7; $r++) {
    $y = $OY + $r * $Step
    W "[MDL$r]"
    W "Meter=String"
    W "X=$Padding"
    W "Y=$y"
    W "W=$DLW"
    W ("H=" + ($CellSize + 2))
    W ("Text=" + $DayNames[$r])
    W "FontColor=$cText"
    W "FontSize=8"
    W "FontFace=Segoe UI"
    W "AntiAlias=1"
    W ""
}

# Contribution cells
$idx = 0
for ($c = 0; $c -lt $Weeks; $c++) {
    for ($r = 0; $r -lt 7; $r++) {
        $cell = $Grid["$c,$r"]
        $cnt  = $cell.count

        # En YearMode, no emitir celdas de años anteriores
        if ($IsYearMode -and ([datetime]$cell.date).Year -lt (Get-Date).Year) {
            $idx++
            continue
        }

        if ($cell.future -or $cnt -le 0) {
            $clr = $cL0
        } elseif ($Max -eq 0) {
            $clr = $cL1
        } else {
            $pct = [double]$cnt / [double]$Max
            if     ($pct -le 0.10) { $clr = $cL1 }
            elseif ($pct -le 0.30) { $clr = $cL2 }
            elseif ($pct -le 0.60) { $clr = $cL3 }
            else                   { $clr = $cL4 }
        }

        $x        = $OX + $c * $Step
        $y        = $OY + $r * $Step
        $diffDays = [int]((Get-Date).Date - (Get-Date $cell.date).Date).TotalDays
        if     ($cell.future)        { $tipDate = $cell.date }
        elseif ($diffDays -eq 0)     { $tipDate = "Today" }
        elseif ($diffDays -eq 1)     { $tipDate = "Yesterday" }
        else                         { $tipDate = "$diffDays days ago" }
        $tip = "$tipDate  -  $cnt contributions"

        W "[MC$idx]"
        W "Meter=Shape"
        W "X=$x"
        W "Y=$y"
        if ($cell.date -eq $todayStr) {
            W ("Shape=Rectangle 0,0," + $CellSize + "," + $CellSize + ",2 | Fill Color " + $clr + " | StrokeWidth 1.5 | Stroke Color " + $cCellTip)
        } else {
            W ("Shape=Rectangle 0,0," + $CellSize + "," + $CellSize + ",2 | Fill Color " + $clr + " | StrokeWidth 0")
        }
        W "ToolTipText=$tip"
        W ""
        $idx++
    }
}

# Row 1: total contributions (ancho completo, sin botones)
$bby = $OY + $GH + 4

$TotalText = "$Total contributions in $((Get-Date).Year)"
W "[MTotal]"
W "Meter=String"
W "X=$Padding"
W "Y=$bby"
W "W=$($WW - $Padding * 2)"
W "H=$BtnRowH"
W "Text=$TotalText"
W "FontColor=$cText"
W "FontSize=10"
W "FontFace=Segoe UI"
W "AntiAlias=1"
W "ClipString=2"
W ""

# Row 2: streak text
$streakText = if ($curStreak -gt 0) { "$curStreak day streak  |  Best: $longestStreak days" } else { "Best: $longestStreak days" }
W "[MStreak]"
W "Meter=String"
W "X=$Padding"
W "Y=$($bby + $BtnRowH)"
W "W=$($WW - $Padding * 2)"
W "H=$StreakH"
W "Text=$streakText"
W "FontColor=$cText"
W "FontSize=10"
W "FontFace=Segoe UI"
W "AntiAlias=1"
W "ClipString=2"
W ""

# Bottom row: icons + Less/More legend + star
$legCS      = [Math]::Min($CellSize, 10)
$legCG      = 2
$legTW      = 26
$legCellsW  = 5 * $legCS + 4 * $legCG
$legTotalW  = $legTW + 4 + $legCellsW + 4 + $legTW
$legX       = [int](($WW - $legTotalW) / 2)
$legY       = $bby + $BtnRowH + $StreakH
$legCY      = $legY + [int](($LegendH - $legCS) / 2)
$legColors  = @($cL0, $cL1, $cL2, $cL3, $cL4)

$iy  = $legY + [int](($LegendH - 20) / 2)
$rix = $Padding + 26

W "[MSettings]"
W "Meter=Image"
W "ImageName=#ROOTCONFIGPATH#@Resources\Icons\settings.png"
W "X=$Padding"
W "Y=$iy"
W "W=20"
W "H=20"
W "LeftMouseUpAction=[`"wscript.exe`" `"#ROOTCONFIGPATH#launch_settings.vbs`"]"
W "ToolTipText=Open Settings"
W ""

W "[MRefresh]"
W "Meter=Image"
W "ImageName=#ROOTCONFIGPATH#@Resources\Icons\refresh.png"
W "X=$rix"
W "Y=$iy"
W "W=20"
W "H=20"
W "LeftMouseUpAction=[`"wscript.exe`" `"#CURRENTPATH#launcher.vbs`"]"
W "ToolTipText=Click to reload (applies Settings.inc changes)"
W ""

W "[MLegLess]"
W "Meter=String"
W "X=$legX"
W "Y=$legY"
W "W=$legTW"
W "H=$($LegendH - 4)"
W "Text=Less"
W "FontColor=$cTextDim"
W "FontSize=8"
W "FontFace=Segoe UI"
W "AntiAlias=1"
W "StringAlign=Right"
W ""

$legCX = $legX + $legTW + 4
for ($li = 0; $li -lt 5; $li++) {
    $lcx = $legCX + $li * ($legCS + $legCG)
    W "[MLegC$li]"
    W "Meter=Shape"
    W "X=$lcx"
    W "Y=$legCY"
    W ("Shape=Rectangle 0,0," + $legCS + "," + $legCS + ",2 | Fill Color " + $legColors[$li] + " | StrokeWidth 0")
    W ""
}

$legMoreX = $legCX + $legCellsW + 4
W "[MLegMore]"
W "Meter=String"
W "X=$legMoreX"
W "Y=$legY"
W "W=$legTW"
W "H=$($LegendH - 4)"
W "Text=More"
W "FontColor=$cTextDim"
W "FontSize=8"
W "FontFace=Segoe UI"
W "AntiAlias=1"
W ""

# Star count - right-aligned
if ($TotalStars -ge 0) {
    $starChar = [char]0x2605
    $starX    = $WW - $Padding - $PBtnW
    $starW    = $PBtnW + $Padding
    W "[MStarCount]"
    W "Meter=String"
    W "X=$starX"
    W "Y=$legY"
    W "W=$starW"
    W "H=$($LegendH - 4)"
    W ("Text=" + $starChar + " " + $TotalStars)
    W "FontColor=210,175,55,220"
    W "FontSize=10"
    W "FontFace=Segoe UI"
    W "AntiAlias=1"
    W ("ToolTipText=Total stars: " + ($configuredRepos -join ', '))
    W ""
}

# Save - UTF-16 LE, atomic write
$content = [string]::Join("`r`n", $lines)
$tempIni = $OutputIni + '.tmp'
[System.IO.File]::WriteAllText($tempIni, $content, [System.Text.Encoding]::Unicode)
Move-Item -Path $tempIni -Destination $OutputIni -Force
L ("Saved: " + $OutputIni + "  cells=" + $idx)

# Trigger Rainmeter skin refresh automatically
$config  = (Split-Path (Split-Path $SkinPath -Parent) -Leaf) + '\' + (Split-Path $SkinPath -Leaf)
$iniFile = [System.IO.Path]::GetFileName($OutputIni)
$rmExe   = "$env:ProgramFiles\Rainmeter\Rainmeter.exe"
if (-not (Test-Path $rmExe)) { $rmExe = "${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe" }
if (Test-Path $rmExe) {
    Start-Process $rmExe -ArgumentList "!Refresh `"$config`" `"$iniFile`""
    L "Rainmeter refresh triggered: $config\$iniFile"
} else {
    L "WARNING: Rainmeter.exe not found - refresh manually"
}

L '=== DONE ==='
Write-Output ("SUCCESS:" + $Total)
