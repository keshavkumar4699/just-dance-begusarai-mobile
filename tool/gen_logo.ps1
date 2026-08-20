# Generates Studio Crow brand assets: gold "SC" monogram in a thin gold ring.
Add-Type -AssemblyName System.Drawing

$gold  = [System.Drawing.Color]::FromArgb(255, 200, 162, 74)   # #C8A24A
$dark  = [System.Drawing.Color]::FromArgb(255, 14, 14, 16)     # #0E0E10

function New-Logo([int]$size, [bool]$withBg, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    if ($withBg) {
        $bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $r = [int]($size * 0.22)  # squircle-ish rounded rect
        $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
        $bgPath.AddArc($rect.X, $rect.Y, $r*2, $r*2, 180, 90)
        $bgPath.AddArc($rect.Right - $r*2, $rect.Y, $r*2, $r*2, 270, 90)
        $bgPath.AddArc($rect.Right - $r*2, $rect.Bottom - $r*2, $r*2, $r*2, 0, 90)
        $bgPath.AddArc($rect.X, $rect.Bottom - $r*2, $r*2, $r*2, 90, 90)
        $bgPath.CloseFigure()
        $g.FillPath((New-Object System.Drawing.SolidBrush($dark)), $bgPath)
    }

    $cx = $size / 2.0
    $ringR = $size * 0.40
    $penW = [Math]::Max(2.0, $size * 0.008)

    # Outer hairline ring
    $pen = New-Object System.Drawing.Pen($gold, $penW)
    $g.DrawEllipse($pen, [float]($cx - $ringR), [float]($cx - $ringR), [float]($ringR*2), [float]($ringR*2))

    # Inner faint ring
    $faint = [System.Drawing.Color]::FromArgb(90, $gold.R, $gold.G, $gold.B)
    $pen2 = New-Object System.Drawing.Pen($faint, [Math]::Max(1.0, $penW * 0.5))
    $ringR2 = $ringR * 0.90
    $g.DrawEllipse($pen2, [float]($cx - $ringR2), [float]($cx - $ringR2), [float]($ringR2*2), [float]($ringR2*2))

    # Monogram
    $font = New-Object System.Drawing.Font("Georgia", [float]($size * 0.30), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush($gold)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $layout = New-Object System.Drawing.RectangleF(0, [float]($cx - $ringR), [float]$size, [float]($ringR * 2))
    $g.DrawString("SC", $font, $brush, $layout, $fmt)

    # Small diamond accents on the ring (left/right)
    $dw = $size * 0.016
    foreach ($dx in @(-$ringR, $ringR)) {
        $pts = @(
            [System.Drawing.PointF]::new([float]($cx + $dx), [float]($cx - $dw)),
            [System.Drawing.PointF]::new([float]($cx + $dx + $dw), [float]$cx),
            [System.Drawing.PointF]::new([float]($cx + $dx), [float]($cx + $dw)),
            [System.Drawing.PointF]::new([float]($cx + $dx - $dw), [float]$cx)
        )
        $g.FillPolygon($brush, $pts)
    }

    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output "wrote $path ($size)"
}

New-Logo -size 1024 -withBg $false -path "assets\logo.png"
New-Logo -size 512  -withBg $true  -path "assets\icon_bg.png"

# Launcher mipmaps (dark rounded square + mark)
$mip = @{ "mdpi"=48; "hdpi"=72; "xhdpi"=96; "xxhdpi"=144; "xxxhdpi"=192 }
foreach ($k in $mip.Keys) {
    $dir = "android\app\src\main\res\mipmap-$k"
    if (Test-Path $dir) { New-Logo -size $mip[$k] -withBg $true -path "$dir\ic_launcher.png" }
}
Write-Output "done"
