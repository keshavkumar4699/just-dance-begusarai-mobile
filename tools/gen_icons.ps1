# Generates Studio Crow logo, student placeholder and Android launcher icons.
# Run: powershell -ExecutionPolicy Bypass -File tools\gen_icons.ps1
Add-Type -AssemblyName System.Drawing

$bg = [System.Drawing.Color]::FromArgb(255, 14, 14, 16)      # #0E0E10
$gold = [System.Drawing.Color]::FromArgb(255, 200, 162, 74)  # #C8A24A

function New-Canvas([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    return @{ bmp = $bmp; g = $g }
}

function Draw-Logo([int]$size, [bool]$transparentBg) {
    $c = New-Canvas $size
    if (-not $transparentBg) {
        $c.g.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), 0, 0, $size, $size)
    }
    $penW = [float]($size * 0.028)
    $ringPen = New-Object System.Drawing.Pen($gold, [Math]::Max(2.0, $penW))
    $m = [float]($size * 0.10)
    $ringW = [float]($size - (2.0 * $m))
    $ringRect = New-Object System.Drawing.RectangleF($m, $m, $ringW, $ringW)
    $c.g.DrawEllipse($ringPen, $ringRect)

    $fs = [float]($size * 0.30)
    $font = New-Object System.Drawing.Font("Segoe UI", $fs, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush($gold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textRect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
    $c.g.DrawString("SC", $font, $brush, $textRect, $sf)
    $c.g.Dispose()
    return $c.bmp
}

function Draw-Placeholder([int]$size) {
    $c = New-Canvas $size
    $c.g.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), 0, 0, $size, $size)
    $brush = New-Object System.Drawing.SolidBrush($gold)
    $headR = [float]($size * 0.14)
    $hx = [float]($size * 0.50)
    $hy = [float]($size * 0.24)
    $c.g.FillEllipse($brush, ($hx - $headR), $hy, (2.0 * $headR), (2.0 * $headR))
    $bw = [float]($size * 0.64)
    $bx = [float]($size * 0.18)
    $by = [float]($size * 0.56)
    $bh = [float]($size * 0.40)
    $c.g.FillPie($brush, $bx, $by, $bw, $bh, 180.0, 180.0)
    $c.g.Dispose()
    return $c.bmp
}

function Save-Image($bmp, [string]$path) {
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

Save-Image (Draw-Logo 1024 $false) "assets\images\logo.png"
Save-Image (Draw-Logo 512 $false) "assets\images\logo_512.png"
Save-Image (Draw-Placeholder 512) "assets\images\placeholder.png"

$densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($k in $densities.Keys) {
    $dir = "android\app\src\main\res\mipmap-$k"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Save-Image (Draw-Logo $densities[$k] $false) "$dir\ic_launcher.png"
    Save-Image (Draw-Logo $densities[$k] $true)  "$dir\ic_launcher_foreground.png"
}
"icons generated"
