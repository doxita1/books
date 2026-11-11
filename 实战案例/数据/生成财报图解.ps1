param(
    [string]$DataPath = (Join-Path $PSScriptRoot '2026三季报核验数据.json'),
    [string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) '图片')
)

# 数据只从核验 JSON 读取；财务金额及桥接贡献均按原表数值计算。
# 用法：pwsh -File .\实战案例\数据\生成财报图解.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$data = Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
$invariant = [System.Globalization.CultureInfo]::InvariantCulture
$midea = $data.midea
$moutai = $data.moutai
$palette = @{
    Background = '#F4F7FB'; Card = '#FFFFFF'; Ink = '#18314B'
    Muted = '#53677D'; Grid = '#D9E3ED'; Blue = '#235F91'
    Teal = '#16877D'; Orange = '#C46935'; LightBlue = '#E7F0F8'
    LightOrange = '#FCF0E7'; LightTeal = '#E6F4F0'
}

function Number($Value) {
    return [decimal]::Parse([string]$Value, $invariant)
}
function Amount($Value) {
    return ([decimal]$Value).ToString('0.00', $invariant)
}
function SignedAmount($Value) {
    if ($Value -ge 0) { return ('+' + (Amount $Value)) }
    return ('−' + (Amount (-$Value)))
}
function Start-Canvas([int]$Width = 1800, [int]$Height = 1180) {
    $script:canvas = [System.Drawing.Bitmap]::new($Width, $Height)
    $script:paint = [System.Drawing.Graphics]::FromImage($script:canvas)
    $script:paint.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $script:paint.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $script:paint.Clear([System.Drawing.ColorTranslator]::FromHtml($palette.Background))
}
function Box([single]$X, [single]$Y, [single]$Width, [single]$Height, [string]$Color) {
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
    try { $script:paint.FillRectangle($brush, $X, $Y, $Width, $Height) }
    finally { $brush.Dispose() }
}
function Line([single]$X1, [single]$Y1, [single]$X2, [single]$Y2,
              [string]$Color, [single]$Width = 2, [bool]$Dashed = $false) {
    $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($Color), $Width)
    if ($Dashed) { $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash }
    try { $script:paint.DrawLine($pen, $X1, $Y1, $X2, $Y2) }
    finally { $pen.Dispose() }
}
function Text([string]$Value, [single]$X, [single]$Y, [single]$Width, [single]$Height,
              [single]$Size = 28, [string]$Color = '#18314B', [bool]$Bold = $false,
              [string]$Align = 'Near') {
    $style = [System.Drawing.FontStyle]::Regular
    if ($Bold) { $style = [System.Drawing.FontStyle]::Bold }
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::$Align
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $format.Trimming = [System.Drawing.StringTrimming]::None
    $font = $null
    try {
        do {
            if ($null -ne $font) { $font.Dispose() }
            $font = [System.Drawing.Font]::new('Microsoft YaHei', $Size, $style,
                [System.Drawing.GraphicsUnit]::Pixel)
            $measured = $script:paint.MeasureString($Value, $font,
                [System.Drawing.SizeF]::new($Width, 10000), $format)
            if ($measured.Height -le $Height -and $measured.Width -le $Width + 1) { break }
            $Size -= 1
        } while ($Size -ge 18)
        if ($measured.Height -gt $Height -or $measured.Width -gt $Width + 1) {
            throw "文字超出预留区域：$Value"
        }
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
        try { $script:paint.DrawString($Value, $font, $brush,
                [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height), $format) }
        finally { $brush.Dispose() }
    }
    finally {
        if ($null -ne $font) { $font.Dispose() }
        $format.Dispose()
    }
}
function Header([string]$Title, [string]$Subtitle, [string]$Tag) {
    Box 64 44 10 64 $palette.Teal
    Text $Title 95 42 1620 70 49 $palette.Ink $true
    Text $Subtitle 96 125 1610 58 27 $palette.Muted
    Text $Tag 96 192 1608 40 24 $palette.Blue $true
}
function Source([object]$Company, [string]$Pages, [string]$Method) {
    Line 82 1055 1718 1055 $palette.Grid 2
    $file = [System.IO.Path]::GetFileName(([uri]$Company.source_url).AbsolutePath)
    Text ('来源：{0}2026年第三季度报告，PDF第{1}页；巨潮资讯，{2}' -f
        $Company.company, $Pages, $file) 86 1072 1630 38 22 $palette.Muted
    Text ('口径：{0}　｜　核验截至：{1}' -f $Method, $data.as_of) 86 1115 1630 38 22 $palette.Muted
}
function Save-Canvas([string]$Name) {
    $target = Join-Path $OutputDirectory $Name
    try { $script:canvas.Save($target, [System.Drawing.Imaging.ImageFormat]::Png) }
    finally { $script:paint.Dispose(); $script:canvas.Dispose() }
    Write-Output $target
}
function Assert-Close([decimal]$Actual, [decimal]$Expected, [string]$Name) {
    if ([math]::Abs($Actual - $Expected) -gt [decimal]0.000001) {
        throw "$Name 未勾稽：$Actual 与 $Expected"
    }
}
function Waterfall-Axes([double]$Max, [double]$Step,
                         [single]$Top = 270, [single]$Bottom = 760) {
    $script:plotTop = $Top
    $script:plotBottom = $Bottom
    $script:plotMax = $Max
    Text '亿元' 86 ($Top - 48) 125 36 24 $palette.Muted
    for ($value = 0; $value -le $Max; $value += $Step) {
        $y = $Bottom - ($value / $Max) * ($Bottom - $Top)
        Line 196 $y 1700 $y $palette.Grid 1
        Text ([string]$value) 80 ($y - 17) 93 38 23 $palette.Muted $false 'Far'
    }
}
function Plot-Y([double]$Value) {
    return [single]($script:plotBottom - ($Value / $script:plotMax) *
        ($script:plotBottom - $script:plotTop))
}
function Waterfall-Bar([single]$X, [single]$Width, [double]$From, [double]$To,
                       [string]$ValueLabel, [string]$Caption, [string]$Color,
                       [string]$Hint = '', [single]$LabelWidth = 260) {
    $top = Plot-Y ([math]::Max($From, $To))
    $bottom = Plot-Y ([math]::Min($From, $To))
    Box $X $top $Width ([math]::Max(3, $bottom - $top)) $Color
    $textX = $X + $Width / 2 - $LabelWidth / 2
    Text $ValueLabel $textX ($top - 55) $LabelWidth 48 34 $Color $true 'Center'
    Text $Caption $textX ($script:plotBottom + 24) $LabelWidth 80 28 $palette.Ink $true 'Center'
    if ($Hint) { Text $Hint $textX ($script:plotBottom + 100) $LabelWidth 45 21 $palette.Muted $false 'Center' }
}

$mideaUnit = Number $data.calculations.midea_conversion_to_yi
$moutaiUnit = Number $data.calculations.moutai_conversion_to_yi
$mideaOld = (Number $midea.cashflow_operating_previous) / $mideaUnit
$mideaNew = (Number $midea.cashflow_operating_current) / $mideaUnit
$mideaInChange = ((Number $midea.cash_in_current) - (Number $midea.cash_in_previous)) / $mideaUnit
$mideaOutEffect = -((Number $midea.cash_out_current) - (Number $midea.cash_out_previous)) / $mideaUnit
Assert-Close ($mideaOld + $mideaInChange + $mideaOutEffect) $mideaNew '美的经营现金流桥'

$moutaiOld = (Number $moutai.cashflow_operating_previous) / $moutaiUnit
$moutaiNew = (Number $moutai.cashflow_operating_current) / $moutaiUnit
$moutaiBankEffect = -((Number $moutai.deposits_to_banks_net_outflow_current) -
    (Number $moutai.deposits_to_banks_net_outflow_previous)) / $moutaiUnit
$moutaiCustomerEffect = ((Number $moutai.customer_deposits_net_current) -
    (Number $moutai.customer_deposits_net_previous)) / $moutaiUnit
$moutaiOther = $moutaiNew - $moutaiOld - $moutaiBankEffect - $moutaiCustomerEffect
Assert-Close ($moutaiOld + $moutaiBankEffect + $moutaiCustomerEffect + $moutaiOther) $moutaiNew '茅台经营现金流桥'

$parentProfit = (Number $midea.parent_profit_current) / $mideaUnit
$nonrecurring = (Number $midea.nonrecurring_net_current) / $mideaUnit
$adjustedProfit = (Number $midea.adjusted_parent_profit_current) / $mideaUnit
Assert-Close ($parentProfit - $nonrecurring) $adjustedProfit '美的利润口径'

# 1. 同一期间的四种指标，保持同比口径而非混用单季数据。
Start-Canvas
Header '美的集团：四个指标，两个方向' `
    ($midea.period + ' 对比 ' + $midea.comparison + '；单位：同比变动百分比') `
    '先分别看收入、归母、扣非和经营现金，再讨论增长质量'
$items = @(
    @{ Label = '营业收入'; Value = (Number $midea.revenue_yoy_pct) },
    @{ Label = '归母净利润'; Value = (Number $midea.parent_profit_yoy_pct) },
    @{ Label = '扣非归母净利润'; Value = (Number $midea.adjusted_parent_profit_yoy_pct) },
    @{ Label = '经营现金流净额'; Value = (Number $midea.cashflow_operating_yoy_pct) }
)
$plotLeft = 430
$plotWidth = 1090
$rangeMin = [math]::Floor((($items.Value | Measure-Object -Minimum).Minimum - 4) / 5) * 5
$rangeMax = [math]::Ceiling((($items.Value | Measure-Object -Maximum).Maximum + 4) / 5) * 5
$scale = $plotWidth / ($rangeMax - $rangeMin)
$zero = $plotLeft + (0 - $rangeMin) * $scale
for ($tick = [math]::Ceiling($rangeMin / 10) * 10; $tick -le $rangeMax; $tick += 10) {
    $tickX = $plotLeft + ($tick - $rangeMin) * $scale
    Line $tickX 292 $tickX 810 $palette.Grid 1
    Text ($tick.ToString('0', $invariant) + '%') ($tickX - 70) 825 140 42 23 $palette.Muted $false 'Center'
}
Line $zero 280 $zero 810 $palette.Blue 3
for ($i = 0; $i -lt $items.Count; $i++) {
    $rowY = 315 + 125 * $i
    $value = $items[$i].Value
    $end = $zero + [double]$value * $scale
    $color = if ($value -ge 0) { $palette.Teal } else { $palette.Orange }
    Text $items[$i].Label 92 ($rowY + 10) 325 64 31 $palette.Ink $true
    Box ([math]::Min($zero, $end)) $rowY ([math]::Max(5, [math]::Abs($end - $zero))) 67 $color
    Text ((SignedAmount $value) + '%') 1537 ($rowY + 8) 185 66 37 $color $true 'Far'
}
Box 86 916 1632 98 $palette.LightBlue
Text '归母利润增长，不能替代对扣非利润与现金流的检查。' 112 936 1580 62 31 $palette.Ink $true
Source $midea ([string]$midea.pages.summary) '合并口径、前三季度累计；同比为公告披露值'
Save-Canvas '美的四指标同比.png'

# 2. 经营流入与流出同比差额对 CFO 变化的算术桥接。
Start-Canvas
Header '美的集团：经营现金流为什么减少？' `
    ($midea.comparison + ' → ' + $midea.period + '；单位：人民币亿元') `
    '现金流入有所增加，但现金流出增加得更多'
$mideaPeak = [double]($mideaOld + $mideaInChange)
$max = [math]::Ceiling(($mideaPeak + 70) / 100) * 100
Waterfall-Axes $max 200
$positions = @(270, 630, 990, 1350)
$barWidth = 210
Waterfall-Bar $positions[0] $barWidth 0 $mideaOld (Amount $mideaOld) '去年同期' $palette.Blue '经营现金流净额'
Waterfall-Bar $positions[1] $barWidth $mideaOld ($mideaOld + $mideaInChange) `
    (SignedAmount $mideaInChange) '流入增加' $palette.Teal '增加经营现金流'
Waterfall-Bar $positions[2] $barWidth ($mideaOld + $mideaInChange) $mideaNew `
    (SignedAmount $mideaOutEffect) '流出增加' $palette.Orange '减少经营现金流'
Waterfall-Bar $positions[3] $barWidth 0 $mideaNew (Amount $mideaNew) '今年同期' $palette.Blue '经营现金流净额'
Line 480 (Plot-Y $mideaOld) 630 (Plot-Y $mideaOld) $palette.Muted 2 $true
Line 840 (Plot-Y ($mideaOld + $mideaInChange)) 990 (Plot-Y ($mideaOld + $mideaInChange)) $palette.Muted 2 $true
Line 1200 (Plot-Y $mideaNew) 1350 (Plot-Y $mideaNew) $palette.Muted 2 $true
Box 86 925 1632 94 $palette.LightBlue
Text ((Amount $mideaOld) + ' + ' + (Amount $mideaInChange) + ' − ' + `
    (Amount (-$mideaOutEffect)) + ' = ' + (Amount $mideaNew) + ' 亿元') `
    105 944 1590 57 36 $palette.Ink $true 'Center'
Source $midea ($midea.pages.cashflow.ToString() + '—' + $midea.pages.cashflow_end.ToString()) `
    '合并经营活动现金流；原表千元除以100,000；显示值保留两位小数'
Save-Canvas '美的经营现金流桥.png'

# 3. 金融类现金流行贡献只解释合并 CFO 的算术变化，不推断酒业分部结果。
Start-Canvas
Header '贵州茅台：经营现金流的变化从哪里来？' `
    ($moutai.comparison + ' → ' + $moutai.period + '；单位：人民币亿元') `
    '这是合并现金流同比变化的算术拆解，不是酒业现金流'
$max = [math]::Ceiling(([double]$moutaiNew + 80) / 100) * 100
Waterfall-Axes $max 200 270 750
$positions = @(245, 535, 825, 1115, 1405)
$barWidth = 170
$afterBank = $moutaiOld + $moutaiBankEffect
$afterCustomer = $afterBank + $moutaiCustomerEffect
Waterfall-Bar $positions[0] $barWidth 0 $moutaiOld (Amount $moutaiOld) '去年同期' $palette.Blue '合并经营现金流' 260
Waterfall-Bar $positions[1] $barWidth $moutaiOld $afterBank (SignedAmount $moutaiBankEffect) `
    "存放央行及`n同业款项变化" $palette.Teal '原表流出行的变化' 260
Waterfall-Bar $positions[2] $barWidth $afterBank $afterCustomer (SignedAmount $moutaiCustomerEffect) `
    "客户存款等`n项目变化" $palette.Teal '原表流入行的变化' 260
Waterfall-Bar $positions[3] $barWidth $afterCustomer $moutaiNew (SignedAmount $moutaiOther) `
    "其余行`n变化合计" $palette.Teal '以总变动减前两项' 260
Waterfall-Bar $positions[4] $barWidth 0 $moutaiNew (Amount $moutaiNew) '今年同期' $palette.Blue '合并经营现金流' 260
$levels = @($moutaiOld, $afterBank, $afterCustomer, $moutaiNew)
for ($i = 0; $i -lt 4; $i++) {
    Line ($positions[$i] + $barWidth) (Plot-Y $levels[$i]) $positions[$i + 1] `
        (Plot-Y $levels[$i]) $palette.Muted 2 $true
}
Box 86 920 1632 102 $palette.LightOrange
Text ((Amount $moutaiOld) + ' + ' + (Amount $moutaiBankEffect) + ' + ' + `
    (Amount $moutaiCustomerEffect) + ' + ' + (Amount $moutaiOther) + ' ≈ ' + `
    (Amount $moutaiNew) + ' 亿元') 104 932 1595 53 31 $palette.Ink $true 'Center'
Text '展示分项有四舍五入尾差；金融类行的贡献不可当作酒业回款。' `
    106 983 1590 33 23 $palette.Orange $true 'Center'
Source $moutai ($moutai.pages.cashflow_start.ToString() + '—' + $moutai.pages.cashflow.ToString()) `
    '合并口径；流出行净增加额保留原正负号后计算；元除以100,000,000'
Save-Canvas '茅台经营现金流桥.png'

# 4. 归母与扣非的勾稽：不把扣非直接叫主营利润或所有者盈余。
Start-Canvas
Header '美的集团：归母与扣非，是两个利润口径' `
    ($midea.period + '累计；单位：人民币亿元') `
    '归母净利润 − 非经常性损益净额 = 扣非归母净利润'
$max = [math]::Ceiling(([double]$parentProfit + 50) / 100) * 100
Waterfall-Axes $max 100 290 720
$positions = @(310, 800, 1290)
$barWidth = 235
Waterfall-Bar $positions[0] $barWidth 0 $parentProfit (Amount $parentProfit) `
    '归母净利润' $palette.Blue '' 360
Waterfall-Bar $positions[1] $barWidth $parentProfit $adjustedProfit ('−' + (Amount $nonrecurring)) `
    '非经常性损益净额' $palette.Orange '' 400
Waterfall-Bar $positions[2] $barWidth 0 $adjustedProfit (Amount $adjustedProfit) `
    '扣非归母净利润' $palette.Teal '' 360
Line 545 (Plot-Y $parentProfit) 800 (Plot-Y $parentProfit) $palette.Muted 2 $true
Line 1035 (Plot-Y $adjustedProfit) 1290 (Plot-Y $adjustedProfit) $palette.Muted 2 $true
Box 86 840 1632 72 $palette.LightBlue
Text '扣非归母净利润 ≠ 主营利润 ≠ 所有者盈余' 108 853 1580 52 32 $palette.Ink $true 'Center'
Box 86 928 1632 98 $palette.LightOrange
Text ('公司对汇兑及衍生品的分类说明，不能推出全部 ' + (Amount $nonrecurring) + `
    ' 亿元均为汇兑损益。') 111 943 1575 66 27 $palette.Orange $true
Source $midea ($midea.pages.summary.ToString() + '、' + $midea.pages.nonrecurring.ToString()) `
    '归属于上市公司股东的利润与非经常性损益净额；千元除以100,000'
Save-Canvas '美的利润口径.png'
