Add-Type -AssemblyName System.Drawing
$outputDirectory = $PSScriptRoot

function Start-Canvas([int]$width, [int]$height) {
    $script:canvas = New-Object System.Drawing.Bitmap($width, $height)
    $script:paint = [System.Drawing.Graphics]::FromImage($script:canvas)
    $script:paint.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $script:paint.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $script:paint.Clear([System.Drawing.ColorTranslator]::FromHtml('#F5F7FB'))
}
function Box([float]$x,[float]$y,[float]$w,[float]$h,[string]$color) {
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $script:paint.FillRectangle($brush,$x,$y,$w,$h)
    $brush.Dispose()
}
function Label([string]$value,[float]$x,[float]$y,[float]$w,[float]$h,[float]$size,[string]$color,[bool]$bold=$false) {
    $style = [System.Drawing.FontStyle]::Regular
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold }
    $font = New-Object System.Drawing.Font('Microsoft YaHei',$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $rect = New-Object System.Drawing.RectangleF($x,$y,$w,$h)
    $script:paint.DrawString($value,$font,$brush,$rect)
    $brush.Dispose()
    $font.Dispose()
}
function Finish-Canvas([string]$fileName) {
    $script:canvas.Save((Join-Path $outputDirectory $fileName),[System.Drawing.Imaging.ImageFormat]::Png)
    $script:paint.Dispose()
    $script:canvas.Dispose()
}

Start-Canvas 1450 1100
Label '财商学习地图' 65 40 1320 65 46 '#14263D' $true
Label '把读书变成六种可检查的能力；每一步都留下一份练习成果。' 68 112 1310 45 26 '#52647A'
$stages = @(
    @('01','资金基础','分清生活需要、近期目标与长期资金','成果：个人资产负债表与现金流记录','入口：合订本第二部分'),
    @('02','企业分析','读懂业务、利润、现金与负债的关系','成果：一页企业研究卡','入口：肖星、巴菲特股东信'),
    @('03','价值与价格','把好企业、好价格和好回报分开','成果：正常与承压情景估值','入口：格雷厄姆、巴菲特、马克斯'),
    @('04','风险管理','检查深度损失、流动性、杠杆与集中度','成果：风险清单与个人约束','入口：马克斯、海龟法则、埃尔德'),
    @('05','证据与判断','检查论证、偏差与可以更新的概率','成果：反证清单与预测日志','入口：学会提问、快与慢、超级预测'),
    @('06','执行与复盘','保留事前理由，区分能力、运气与成本','成果：个人政策与复盘记录','入口：交易回忆录、埃尔德、全书整合')
)
for ($i=0; $i -lt $stages.Count; $i++) {
    $rowY = 185 + 132*$i
    Box 65 $rowY 1320 114 '#FFFFFF'
    Box 65 $rowY 100 114 '#245E82'
    Label $stages[$i][0] 85 ($rowY+27) 80 60 40 '#FFFFFF' $true
    Label $stages[$i][1] 190 ($rowY+14) 270 48 31 '#14263D' $true
    Label $stages[$i][2] 470 ($rowY+17) 890 42 26 '#14263D'
    Label $stages[$i][3] 190 ($rowY+67) 640 36 23 '#52647A'
    Label $stages[$i][4] 830 ($rowY+68) 540 36 21 '#52647A'
}
Label '建议从资金和财报开始；交易规则另设研究流程，避免与长期投资的依据混用。' 68 1010 1310 55 24 '#52647A'
Finish-Canvas '财商学习地图.png'

Start-Canvas 1450 1000
Label '亏损与回本，并不对称' 65 42 1320 65 44 '#14263D' $true
Label '回本所需涨幅 = 回撤比例 ÷（1 − 回撤比例）' 68 116 1300 50 29 '#52647A'
Label '回撤' 72 196 200 40 24 '#52647A'
Label '回到原点所需涨幅' 320 196 900 40 24 '#52647A'
$losses = @(0.10,0.20,0.30,0.50,0.70)
$chartX = 320
$scale = 900 / 2.5
for ($i=0; $i -lt $losses.Count; $i++) {
    $rowY = 260 + $i*112
    $recovery = $losses[$i] / (1-$losses[$i])
    Label ('-{0:0}%' -f ($losses[$i]*100)) 80 ($rowY+6) 200 60 35 '#14263D' $true
    Box $chartX $rowY 900 64 '#E5EBF3'
    Box $chartX $rowY ([float]($recovery*$scale)) 64 '#247A86'
    Label ('+{0:0.0}%' -f ($recovery*100)) 1240 ($rowY+8) 190 55 31 '#14263D' $true
}
Box 68 855 1310 90 '#E5EDF7'
Label '示例：100 元亏 50% 后剩 50 元；再涨 50% 只有 75 元，涨 100% 才回到 100 元。' 88 870 1270 63 25 '#14263D'
Label '数据为数学公式计算的教学示例，不是行情预测。' 70 956 1300 35 20 '#52647A'
Finish-Canvas '回撤与回本.png'
