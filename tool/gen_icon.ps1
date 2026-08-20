# Generates Android launcher icons from assets/logo.png with slightly
# rounded corners (radius ~15% of size), transparent outside the corners.
Add-Type -AssemblyName System.Drawing

$src = (Resolve-Path "assets\logo.png").Path
$srcBmp = [System.Drawing.Bitmap]::FromFile($src)

$mip = @{ "mdpi"=48; "hdpi"=72; "xhdpi"=96; "xxhdpi"=144; "xxxhdpi"=192 }
foreach ($k in $mip.Keys) {
    $size = $mip[$k]
    $dir = "android\app\src\main\res\mipmap-$k"
    if (-not (Test-Path $dir)) { Write-Output "skip $dir (missing)"; continue }

    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $r = [int]($size * 0.15)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($rect.X, $rect.Y, $r*2, $r*2, 180, 90)
    $path.AddArc($rect.Right - $r*2, $rect.Y, $r*2, $r*2, 270, 90)
    $path.AddArc($rect.Right - $r*2, $rect.Bottom - $r*2, $r*2, $r*2, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $r*2, $r*2, $r*2, 90, 90)
    $path.CloseFigure()
    $g.SetClip($path)
    $g.DrawImage($srcBmp, $rect)
    $g.ResetClip()

    $bmp.Save((Join-Path $dir "ic_launcher.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output "wrote $dir\ic_launcher.png ($size)"
}
$srcBmp.Dispose()
Write-Output "done"
