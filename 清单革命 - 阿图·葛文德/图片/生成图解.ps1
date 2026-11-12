# 数据：Haynes et al., NEJM 2009, DOI 10.1056/NEJMsa0810119。
# 研究为八家医院实施前后比较；不能由此单独识别清单的纯因果效果。
Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap(1500, 960)
$paint = [System.Drawing.Graphics]::FromImage($bitmap)
$paint.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$paint.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$paint.Clear([System.Drawing.ColorTranslator]::FromHtml('#F4F7FB'))
function Box([float]$x,[float]$y,[float]$w,[float]$h,[string]$color) {
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $paint.FillRectangle($brush,$x,$y,$w,$h)
    $brush.Dispose()
}
function Label([string]$value,[float]$x,[float]$y,[float]$w,[float]$h,[float]$size,[string]$color,[bool]$bold=$false) {
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    $font = New-Object System.Drawing.Font('Microsoft YaHei',$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $paint.DrawString($value,$font,$brush,(New-Object System.Drawing.RectangleF($x,$y,$w,$h)))
    $font.Dispose()
    $brush.Dispose()
}
function Line([float]$x1,[float]$y1,[float]$x2,[float]$y2,[string]$color) {
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($color),1)
    $paint.DrawLine($pen,$x1,$y1,$x2,$y2)
    $pen.Dispose()
}
Label '清单实施前后：结果改善，但因果解释仍有边界' 55 30 1400 65 40 '#17314A' $true
Label '八家医院｜实施前 3,733 人；实施后 3,955 人｜2007—2008 年收集，2009 年发表' 60 105 1380 45 25 '#526479'
Box 60 180 1380 540 '#FFFFFF'
Label '发生率（%）' 85 195 240 35 25 '#17314A'
Box 1010 200 25 25 '#67839A'
Label '实施前' 1045 193 145 40 25 '#17314A'
Box 1200 200 25 25 '#008D87'
Label '实施后' 1235 193 150 40 25 '#17314A'
for ($tick=0; $tick -le 12; $tick+=2) {
    $lineY=650-$tick*30
    Line 160 $lineY 1360 $lineY '#DDE5EC'
    Label ([string]$tick) 100 ($lineY-18) 55 40 23 '#526479'
}
$bars=@(
    @{x=335;v=1.5;c='#67839A'},
    @{x=495;v=0.8;c='#008D87'},
    @{x=925;v=11.0;c='#67839A'},
    @{x=1085;v=7.0;c='#008D87'}
)
foreach ($entry in $bars) {
    $barH=$entry.v*30
    Box $entry.x (650-$barH) 110 $barH $entry.c
    Label ($entry.v.ToString('0.0')+'%') ($entry.x+5) (600-$barH) 130 45 30 '#17314A' $true
}
Label '死亡率：1.5% → 0.8%' 300 667 440 40 27 '#17314A' $true
Label '并发症（含死亡）：11.0% → 7.0%' 790 667 640 40 27 '#17314A' $true
Label '绝对下降 0.7 个百分点；相对约 46.7%' 85 745 645 45 26 '#17314A'
Label '绝对下降 4.0 个百分点；相对约 36.4%' 765 745 665 45 26 '#17314A'
Label '观察范围：住院期间、术后前 30 天。图中两组共用从 0 开始的纵轴。' 65 805 1380 40 23 '#526479'
Label '前后比较并非随机分组；培训、实施方式和其他变化也可能影响结果。' 65 849 1380 40 25 '#A3432E' $true
Label '来源：Haynes 等，NEJM 2009；DOI 10.1056/NEJMsa0810119。比例为论文报告值。' 65 903 1380 35 21 '#526479'
$bitmap.Save((Join-Path $PSScriptRoot '清单研究前后对照.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$paint.Dispose()
$bitmap.Dispose()
