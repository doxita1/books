Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap(1600, 980)
$paint = [System.Drawing.Graphics]::FromImage($bitmap)
$paint.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$paint.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$paint.Clear([System.Drawing.ColorTranslator]::FromHtml('#F4F7FB'))
function Box([float]$x,[float]$y,[float]$width,[float]$height,[string]$color) {
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $paint.FillRectangle($brush,$x,$y,$width,$height)
    $brush.Dispose()
}
function Label([string]$value,[float]$x,[float]$y,[float]$width,[float]$height,[float]$size,[string]$color,[bool]$bold=$false) {
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    $font = New-Object System.Drawing.Font('Microsoft YaHei',$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $rectangle = New-Object System.Drawing.RectangleF($x,$y,$width,$height)
    $paint.DrawString($value,$font,$brush,$rectangle)
    $font.Dispose()
    $brush.Dispose()
}
function Line([float]$x1,[float]$y1,[float]$x2,[float]$y2,[string]$color,[float]$width=1) {
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($color),$width)
    $paint.DrawLine($pen,$x1,$y1,$x2,$y2)
    $pen.Dispose()
}

Label '数字没变，视觉印象却变了' 60 35 1480 75 46 '#17314A' $true
Label '2024 年全国居民人均可支配收入｜单位：元／年' 64 115 1470 45 27 '#526479'
Box 60 190 715 535 '#FFFFFF'
Box 825 190 715 535 '#FFFFFF'
Label '纵轴从 0 开始' 100 210 620 45 29 '#17314A' $true
Label '教学演示：纵轴从 30,000 开始' 855 210 650 45 29 '#A3432E' $true

$values = @(41314,34707)
$names = @('平均数','中位数')
$colors = @('#287B96','#E19A3E')
for ($panel=0;$panel -lt 2;$panel++) {
    $left = 165 + $panel*765
    $top = 295
    $bottom = 640
    $floor = 0
    $ticks = @(0,15000,30000,45000)
    if ($panel -eq 1) { $floor=30000; $ticks=@(30000,35000,40000,45000) }
    foreach ($tick in $ticks) {
        $tickY = $bottom - (($tick-$floor)/(45000-$floor))*($bottom-$top)
        Line $left $tickY ($left+515) $tickY '#DDE5ED'
        Label ('{0:N0}' -f $tick) ($left-100) ($tickY-14) 95 35 21 '#526479'
    }
    for ($i=0;$i -lt 2;$i++) {
        $barX = $left+80+$i*235
        $height = (($values[$i]-$floor)/(45000-$floor))*($bottom-$top)
        Box $barX ($bottom-$height) 140 $height $colors[$i]
        Label ('{0:N0}' -f $values[$i]) ($barX-7) ($bottom-$height-42) 165 40 29 '#17314A' $true
        Label $names[$i] ($barX+12) ($bottom+15) 150 40 25 '#17314A'
    }
    Line $left $bottom ($left+515) $bottom '#526479' 2
    if ($panel -eq 1) {
        Line ($left-7) ($bottom-13) ($left+7) ($bottom-23) '#A3432E' 3
        Line ($left-7) ($bottom-3) ($left+7) ($bottom-13) '#A3432E' 3
    }
}
Box 60 750 1480 130 '#E6EDF5'
Label '实际比值约 1.19 倍；截断后的可见柱高却约 2.40 倍。' 85 766 1430 45 30 '#17314A' $true
Label '右图省略了 0—30,000，不能按可见柱高比较实际收入倍数。两图使用完全相同的数值。' 85 821 1430 43 23 '#526479'
Label '来源：国家统计局《2024 年居民收入和消费支出情况》，2025-01-17。' 65 905 1470 35 22 '#526479'
Label '本图为自行绘制的读图教学；并非统计局原图。平均数与中位数也不是两个不同人群。' 65 944 1470 30 20 '#526479'
$destination = Join-Path $PSScriptRoot '同一数据不同纵轴.png'
$bitmap.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
$paint.Dispose()
$bitmap.Dispose()
Write-Output $destination
