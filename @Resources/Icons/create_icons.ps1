# =============================================================
#  grassmeter - create_icons.ps1
#  Generates settings.png and refresh.png using System.Drawing
# =============================================================
Add-Type -AssemblyName System.Drawing

$outDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$S      = [int]20
$clr    = [System.Drawing.Color]::FromArgb(88, 96, 105)

# ------------------------------------------------------------------
# settings.png  (gear / cog icon)
# ------------------------------------------------------------------
$bmp = [System.Drawing.Bitmap]::new($S, $S, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode   = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::Transparent)

$brush = [System.Drawing.SolidBrush]::new($clr)
$cx    = [double]($S / 2)
$cy    = [double]($S / 2)

$nTeeth    = 8
$outerR    = $S * 0.46
$valleyR   = $S * 0.30
$holeR     = $S * 0.17
$toothHalf = [Math]::PI / $nTeeth * 0.55

$pts = [System.Collections.Generic.List[System.Drawing.PointF]]::new()
for ($i = 0; $i -lt $nTeeth; $i++) {
    $base = 2.0 * [Math]::PI * $i / $nTeeth

    $a = $base - $toothHalf
    $pts.Add([System.Drawing.PointF]::new($cx + $valleyR * [Math]::Cos($a), $cy + $valleyR * [Math]::Sin($a)))

    $a = $base - $toothHalf * 0.3
    $pts.Add([System.Drawing.PointF]::new($cx + $outerR * [Math]::Cos($a), $cy + $outerR * [Math]::Sin($a)))

    $a = $base + $toothHalf * 0.3
    $pts.Add([System.Drawing.PointF]::new($cx + $outerR * [Math]::Cos($a), $cy + $outerR * [Math]::Sin($a)))

    $a = $base + $toothHalf
    $pts.Add([System.Drawing.PointF]::new($cx + $valleyR * [Math]::Cos($a), $cy + $valleyR * [Math]::Sin($a)))
}

$gearPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$gearPath.AddPolygon($pts.ToArray())
$gearPath.AddEllipse([float]($cx - $holeR), [float]($cy - $holeR), [float]($holeR * 2), [float]($holeR * 2))
$gearPath.FillMode = [System.Drawing.Drawing2D.FillMode]::Alternate
$g.FillPath($brush, $gearPath)

$bmp.Save((Join-Path $outDir 'settings.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$gearPath.Dispose(); $brush.Dispose(); $g.Dispose(); $bmp.Dispose()

# ------------------------------------------------------------------
# refresh.png  (circular arrow)
# ------------------------------------------------------------------
$bmp = [System.Drawing.Bitmap]::new($S, $S, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode   = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::Transparent)

$pen        = [System.Drawing.Pen]::new($clr, [float]2.2)
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$arrowBrush = [System.Drawing.SolidBrush]::new($clr)

$cx = [double]($S / 2)
$cy = [double]($S / 2)
$r  = $S * 0.36

$startDeg = [float](-210.0)
$sweepDeg = [float](300.0)
$rx = [float]($cx - $r); $ry = [float]($cy - $r); $rw = [float]($r * 2)
$rect = [System.Drawing.RectangleF]::new($rx, $ry, $rw, $rw)
$g.DrawArc($pen, $rect, $startDeg, $sweepDeg)

# Arrowhead at arc end
$endRad = ($startDeg + $sweepDeg) * [Math]::PI / 180.0
$ex = $cx + $r * [Math]::Cos($endRad)
$ey = $cy + $r * [Math]::Sin($endRad)
$tx =  -[Math]::Sin($endRad)   # tangent (clockwise)
$ty =   [Math]::Cos($endRad)
$nx =  -[Math]::Cos($endRad)   # normal (inward)
$ny =  -[Math]::Sin($endRad)

$al = $S * 0.26
$aw = $S * 0.16
$arrowPts = @(
    [System.Drawing.PointF]::new($ex + $tx * $al,  $ey + $ty * $al),
    [System.Drawing.PointF]::new($ex + $nx * $aw,  $ey + $ny * $aw),
    [System.Drawing.PointF]::new($ex - $nx * $aw,  $ey - $ny * $aw)
)
$g.FillPolygon($arrowBrush, $arrowPts)

$bmp.Save((Join-Path $outDir 'refresh.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pen.Dispose(); $arrowBrush.Dispose(); $g.Dispose(); $bmp.Dispose()

Write-Host "Done: settings.png, refresh.png"
