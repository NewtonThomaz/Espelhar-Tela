Add-Type -AssemblyName System.Drawing

function Create-AppIcon {
    param (
        [string]$IcoPath
    )

    $sizes = @(256, 64, 48, 32, 16)
    $images = [System.Collections.Generic.List[System.Drawing.Bitmap]]::new()

    foreach ($size in $sizes) {
        $bmp = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.Clear([System.Drawing.Color]::Transparent)

        $scale = $size / 256.0

        # Background rounded tile (#0F172A)
        $bgRect = [System.Drawing.RectangleF]::new(12 * $scale, 12 * $scale, 232 * $scale, 232 * $scale)
        $bgPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $radius = 48.0 * $scale
        $d = $radius * 2

        $bgPath.AddArc($bgRect.X, $bgRect.Y, $d, $d, 180, 90)
        $bgPath.AddArc($bgRect.Right - $d, $bgRect.Y, $d, $d, 270, 90)
        $bgPath.AddArc($bgRect.Right - $d, $bgRect.Bottom - $d, $d, $d, 0, 90)
        $bgPath.AddArc($bgRect.X, $bgRect.Bottom - $d, $d, $d, 90, 90)
        $bgPath.CloseFigure()

        $bgBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 15, 23, 42))
        $g.FillPath($bgBrush, $bgPath)
        $bgBrush.Dispose()

        # Subtle border (#1E293B)
        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 30, 41, 59), 4 * $scale)
        $g.DrawPath($borderPen, $bgPath)
        $borderPen.Dispose()
        $bgPath.Dispose()

        # Monitor Bezel / Outer Screen (#10B981)
        # Coordinates based on SVG path M21,3H3...
        $mX = 40.0 * $scale
        $mY = 44.0 * $scale
        $mW = 176.0 * $scale
        $mH = 120.0 * $scale
        $mR = 14.0 * $scale
        $mD = $mR * 2

        $monPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $monPath.AddArc($mX, $mY, $mD, $mD, 180, 90)
        $monPath.AddArc($mX + $mW - $mD, $mY, $mD, $mD, 270, 90)
        $monPath.AddArc($mX + $mW - $mD, $mY + $mH - $mD, $mD, $mD, 0, 90)
        $monPath.AddArc($mX, $mY + $mH - $mD, $mD, $mD, 90, 90)
        $monPath.CloseFigure()

        $monPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 16, 185, 129), 10 * $scale)
        $monPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $g.DrawPath($monPen, $monPath)
        $monPen.Dispose()
        $monPath.Dispose()

        # Monitor Stand and Base (#10B981)
        $standBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 16, 185, 129))
        $standRect = [System.Drawing.RectangleF]::new(118 * $scale, 164 * $scale, 20 * $scale, 28 * $scale)
        $g.FillRectangle($standBrush, $standRect)

        $basePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $baseRect = [System.Drawing.RectangleF]::new(88 * $scale, 188 * $scale, 80 * $scale, 12 * $scale)
        $bR = 6.0 * $scale
        $bRD = $bR * 2
        $basePath.AddArc($baseRect.X, $baseRect.Y, $bRD, $bRD, 180, 90)
        $basePath.AddArc($baseRect.Right - $bRD, $baseRect.Y, $bRD, $bRD, 270, 90)
        $basePath.AddArc($baseRect.Right - $bRD, $baseRect.Bottom - $bRD, $bRD, $bRD, 0, 90)
        $basePath.AddArc($baseRect.X, $baseRect.Bottom - $bRD, $bRD, $bRD, 90, 90)
        $basePath.CloseFigure()
        $g.FillPath($standBrush, $basePath)
        $basePath.Dispose()
        $standBrush.Dispose()

        # Phone in Center (#34D399)
        # Inner phone shape
        $pX = 96.0 * $scale
        $pY = 64.0 * $scale
        $pW = 64.0 * $scale
        $pH = 80.0 * $scale
        $pR = 10.0 * $scale
        $pD = $pR * 2

        $phonePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $phonePath.AddArc($pX, $pY, $pD, $pD, 180, 90)
        $phonePath.AddArc($pX + $pW - $pD, $pY, $pD, $pD, 270, 90)
        $phonePath.AddArc($pX + $pW - $pD, $pY + $pH - $pD, $pD, $pD, 0, 90)
        $phonePath.AddArc($pX, $pY + $pH - $pD, $pD, $pD, 90, 90)
        $phonePath.CloseFigure()

        $phoneBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 211, 153))
        $g.FillPath($phoneBrush, $phonePath)
        $phoneBrush.Dispose()

        # Phone screen cut-out (#0F172A)
        $scrPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $sX = 104.0 * $scale
        $sY = 74.0 * $scale
        $sW = 48.0 * $scale
        $sH = 58.0 * $scale
        $sR = 5.0 * $scale
        $sD = $sR * 2
        $scrPath.AddArc($sX, $sY, $sD, $sD, 180, 90)
        $scrPath.AddArc($sX + $sW - $sD, $sY, $sD, $sD, 270, 90)
        $scrPath.AddArc($sX + $sW - $sD, $sY + $sH - $sD, $sD, $sD, 0, 90)
        $scrPath.AddArc($sX, $sY + $sH - $sD, $sD, $sD, 90, 90)
        $scrPath.CloseFigure()

        $screenBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 15, 23, 42))
        $g.FillPath($screenBrush, $scrPath)
        $screenBrush.Dispose()
        $scrPath.Dispose()

        # Phone home indicator line (#34D399)
        $barBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 211, 153))
        $g.FillRectangle($barBrush, [System.Drawing.RectangleF]::new(120 * $scale, 137 * $scale, 16 * $scale, 3 * $scale))
        $barBrush.Dispose()

        $phonePath.Dispose()
        $g.Dispose()

        $images.Add($bmp)
    }

    # Write multi-resolution Windows .ico
    $fs = [System.IO.FileStream]::new($IcoPath, [System.IO.FileMode]::Create)
    $bw = [System.IO.BinaryWriter]::new($fs)

    # ICONDIR header: Reserved (0), Type (1 = ICO), ImageCount
    $bw.Write([uint16]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]$images.Count)

    $offset = 6 + ($images.Count * 16)
    $pngBuffers = [System.Collections.Generic.List[byte[]]]::new()

    foreach ($img in $images) {
        $ms = [System.IO.MemoryStream]::new()
        $img.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngData = $ms.ToArray()
        $pngBuffers.Add($pngData)
        $ms.Dispose()

        $w = if ($img.Width -ge 256) { [byte]0 } else { [byte]$img.Width }
        $h = if ($img.Height -ge 256) { [byte]0 } else { [byte]$img.Height }

        $bw.Write($w)               # Width
        $bw.Write($h)               # Height
        $bw.Write([byte]0)          # ColorCount
        $bw.Write([byte]0)          # Reserved
        $bw.Write([uint16]1)        # Planes
        $bw.Write([uint16]32)       # BitCount
        $bw.Write([uint32]$pngData.Length) # BytesInRes
        $bw.Write([uint32]$offset)  # ImageOffset

        $offset += $pngData.Length
    }

    foreach ($data in $pngBuffers) {
        $bw.Write($data)
    }

    $bw.Flush()
    $fs.Close()

    foreach ($img in $images) {
        $img.Dispose()
    }
}

$targetIco = if ($PSScriptRoot) { Join-Path $PSScriptRoot "celular.ico" } else { "celular.ico" }
Create-AppIcon -IcoPath $targetIco
Write-Output "Icon generated successfully at: $targetIco"

