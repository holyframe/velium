$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$builderImageRoot = Join-Path $PSScriptRoot 'images'
$iconDirectory = Join-Path $builderImageRoot 'icons'
$rendererImageRoot = Join-Path $projectRoot 'src\assets\images'

function New-RoundedRectanglePath {
  param(
    [float] $X,
    [float] $Y,
    [float] $Width,
    [float] $Height,
    [float] $Radius
  )

  $diameter = $Radius * 2
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-VeliumBitmap {
  param(
    [int] $Size,
    [ValidateSet('normal', 'unread', 'indirect')]
    [string] $Variant = 'normal'
  )

  $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)

  $scale = $Size / 1024.0
  $background = New-RoundedRectanglePath (52 * $scale) (52 * $scale) (920 * $scale) (920 * $scale) (190 * $scale)
  $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.PointF]::new([float] (110 * $scale), [float] (70 * $scale)),
    [System.Drawing.PointF]::new([float] (900 * $scale), [float] (950 * $scale)),
    [System.Drawing.Color]::FromArgb(255, 109, 94, 246),
    [System.Drawing.Color]::FromArgb(255, 23, 17, 63)
  )
  $graphics.FillPath($gradient, $background)

  $highlightPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $highlightPath.AddEllipse(125 * $scale, 70 * $scale, 790 * $scale, 430 * $scale)
  $highlightBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.PointF]::new([float] (512 * $scale), [float] (70 * $scale)),
    [System.Drawing.PointF]::new([float] (512 * $scale), [float] (500 * $scale)),
    [System.Drawing.Color]::FromArgb(65, 255, 255, 255),
    [System.Drawing.Color]::FromArgb(0, 255, 255, 255)
  )
  $graphics.SetClip($background)
  $graphics.FillPath($highlightBrush, $highlightPath)
  $graphics.ResetClip()

  $leftPoints = [System.Drawing.PointF[]] @(
    [System.Drawing.PointF]::new([float] (190 * $scale), [float] (245 * $scale)),
    [System.Drawing.PointF]::new([float] (360 * $scale), [float] (245 * $scale)),
    [System.Drawing.PointF]::new([float] (512 * $scale), [float] (625 * $scale)),
    [System.Drawing.PointF]::new([float] (464 * $scale), [float] (820 * $scale))
  )
  $rightPoints = [System.Drawing.PointF[]] @(
    [System.Drawing.PointF]::new([float] (512 * $scale), [float] (625 * $scale)),
    [System.Drawing.PointF]::new([float] (664 * $scale), [float] (245 * $scale)),
    [System.Drawing.PointF]::new([float] (834 * $scale), [float] (245 * $scale)),
    [System.Drawing.PointF]::new([float] (560 * $scale), [float] (820 * $scale)),
    [System.Drawing.PointF]::new([float] (464 * $scale), [float] (820 * $scale))
  )
  $leftBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
  $rightBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 91, 226, 255))
  $graphics.FillPolygon($leftBrush, $leftPoints)
  $graphics.FillPolygon($rightBrush, $rightPoints)

  if ($Variant -ne 'normal') {
    $dotColor = if ($Variant -eq 'unread') {
      [System.Drawing.Color]::FromArgb(255, 244, 63, 94)
    } else {
      [System.Drawing.Color]::FromArgb(255, 250, 204, 21)
    }
    $dotOutline = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 23, 17, 63))
    $dotBrush = [System.Drawing.SolidBrush]::new($dotColor)
    $graphics.FillEllipse($dotOutline, 682 * $scale, 682 * $scale, 230 * $scale, 230 * $scale)
    $graphics.FillEllipse($dotBrush, 711 * $scale, 711 * $scale, 172 * $scale, 172 * $scale)
    $dotOutline.Dispose()
    $dotBrush.Dispose()
  }

  $leftBrush.Dispose()
  $rightBrush.Dispose()
  $highlightBrush.Dispose()
  $highlightPath.Dispose()
  $gradient.Dispose()
  $background.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function ConvertTo-PngBytes {
  param([System.Drawing.Bitmap] $Bitmap)

  $stream = [System.IO.MemoryStream]::new()
  $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
  $bytes = $stream.ToArray()
  $stream.Dispose()
  return ,$bytes
}

function Write-VeliumIco {
  param(
    [string] $Path,
    [string] $Variant = 'normal'
  )

  $sizes = @(16, 24, 32, 48, 64, 128, 256)
  $payloads = [System.Collections.Generic.List[byte[]]]::new()
  foreach ($size in $sizes) {
    $bitmap = New-VeliumBitmap -Size $size -Variant $Variant
    [byte[]] $bytes = ConvertTo-PngBytes -Bitmap $bitmap
    $bitmap.Dispose()
    $payloads.Add($bytes)
  }

  $stream = [System.IO.MemoryStream]::new()
  $writer = [System.IO.BinaryWriter]::new($stream)
  $writer.Write([uint16] 0)
  $writer.Write([uint16] 1)
  $writer.Write([uint16] $sizes.Count)
  $offset = 6 + (16 * $sizes.Count)

  for ($index = 0; $index -lt $sizes.Count; $index++) {
    $dimension = if ($sizes[$index] -eq 256) { 0 } else { $sizes[$index] }
    $writer.Write([byte] $dimension)
    $writer.Write([byte] $dimension)
    $writer.Write([byte] 0)
    $writer.Write([byte] 0)
    $writer.Write([uint16] 1)
    $writer.Write([uint16] 32)
    $writer.Write([uint32] $payloads[$index].Length)
    $writer.Write([uint32] $offset)
    $offset += $payloads[$index].Length
  }

  foreach ($payload in $payloads) {
    $writer.Write([byte[]] $payload)
  }

  $writer.Flush()
  [System.IO.File]::WriteAllBytes($Path, $stream.ToArray())
  $writer.Dispose()
  $stream.Dispose()
}

New-Item -ItemType Directory -Force -Path $iconDirectory | Out-Null

foreach ($size in @(16, 24, 32, 48, 64, 96, 128, 256, 512, 1024)) {
  $bitmap = New-VeliumBitmap -Size $size
  $bitmap.Save((Join-Path $iconDirectory ("{0}x{0}.png" -f $size)), [System.Drawing.Imaging.ImageFormat]::Png)
  if ($size -eq 1024) {
    $bitmap.Save((Join-Path $builderImageRoot 'icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  }
  if ($size -eq 256) {
    $bitmap.Save((Join-Path $rendererImageRoot 'icons\256x256.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  }
  $bitmap.Dispose()
}

Write-VeliumIco -Path (Join-Path $builderImageRoot 'icon.ico')
Write-VeliumIco -Path (Join-Path $builderImageRoot 'win-app-ico.ico')
Write-VeliumIco -Path (Join-Path $rendererImageRoot 'taskbar\win32\display.ico')
Write-VeliumIco -Path (Join-Path $rendererImageRoot 'tray\win32\tray.ico')
Write-VeliumIco -Path (Join-Path $rendererImageRoot 'tray\win32\tray-unread.ico') -Variant 'unread'
Write-VeliumIco -Path (Join-Path $rendererImageRoot 'tray\win32\tray-indirect.ico') -Variant 'indirect'

Write-Output 'Velium icon assets generated.'
