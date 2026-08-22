<#
  블랙잭 카드 그림 만들기.

  원본 두 장을 잘라 카드 53장(52장 + 뒷면)을 64x64 정사각 그림으로 만든다.
    포커.png     … 13x4 로 늘어놓은 카드 앞면
    덮힌카드.png … 카드 뒷면

  마인크래프트 물건 그림은 정사각이어야 하므로, 카드를 가운데 놓고
  남는 자리는 투명하게 둔다. 카드 바깥의 흰 여백도 투명으로 지운다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$SrcDir = 'C:\Users\dredr\OneDrive\바탕 화면\블랙잭 카드'
$OutDir = Join-Path $PSScriptRoot 'blackjack'
New-Item -ItemType Directory -Force $OutDir | Out-Null

$CANVAS = 64

# 원본에서 카드 한 장이 차지하는 자리 (빈칸을 훑어 찾아낸 값)
$colX = @(7,61,116,170,225,279,334,388,443,497,552,606,661)
$colW = @(44,45,44,45,44,45,44,45,44,45,44,45,44)
$rowY = @(98,171,245,318)
$rowH = @(63,64,63,64)

$suits = @('h','d','c','s')                                        # 하트 다이아 클로버 스페이드
$ranks = @('a','2','3','4','5','6','7','8','9','10','j','q','k')

function New-Canvas([System.Drawing.Bitmap]$card) {
    $out = New-Object Drawing.Bitmap($CANVAS, $CANVAS, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode   = [Drawing.Drawing2D.PixelOffsetMode]::Half
    # 카드 높이를 판 높이에 맞추고 가로 비율은 그대로 둔다
    $scale = $CANVAS / $card.Height
    $w = [int][math]::Round($card.Width * $scale)
    $h = $CANVAS
    $g.DrawImage($card, [int](($CANVAS - $w) / 2), 0, $w, $h)
    $g.Dispose()
    return $out
}

# 카드 바깥의 흰 여백을 투명으로 (네 귀퉁이에서 번져 들어간다)
function Clear-Outside([System.Drawing.Bitmap]$bmp) {
    $w = $bmp.Width; $h = $bmp.Height
    $seen = New-Object 'bool[]' ($w * $h)
    $stack = New-Object System.Collections.Generic.Stack[int]
    foreach ($p in @(0, ($w-1), ($w*($h-1)), ($w*$h-1))) { $stack.Push($p) }
    while ($stack.Count -gt 0) {
        $i = $stack.Pop()
        if ($seen[$i]) { continue }
        $seen[$i] = $true
        $x = $i % $w; $y = [int](($i - $x) / $w)
        $c = $bmp.GetPixel($x, $y)
        $white = ($c.A -lt 40) -or (($c.R + $c.G + $c.B) -gt 720)
        if (-not $white) { continue }
        $bmp.SetPixel($x, $y, [Drawing.Color]::FromArgb(0,0,0,0))
        if ($x -gt 0)      { $stack.Push($i - 1) }
        if ($x -lt $w - 1) { $stack.Push($i + 1) }
        if ($y -gt 0)      { $stack.Push($i - $w) }
        if ($y -lt $h - 1) { $stack.Push($i + $w) }
    }
}

# ── 앞면 52장 ────────────────────────────────────────────────────
$sheet = [Drawing.Bitmap]::FromFile((Join-Path $SrcDir '포커.png'))
for ($r = 0; $r -lt 4; $r++) {
    for ($c = 0; $c -lt 13; $c++) {
        $rect = New-Object Drawing.Rectangle($colX[$c], $rowY[$r], $colW[$c], $rowH[$r])
        $card = $sheet.Clone($rect, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $out = New-Canvas $card
        Clear-Outside $out
        $out.Save((Join-Path $OutDir ("card_" + $suits[$r] + "_" + $ranks[$c] + ".png")),
                  [Drawing.Imaging.ImageFormat]::Png)
        $out.Dispose(); $card.Dispose()
    }
}
$sheet.Dispose()

# ── 뒷면 ─────────────────────────────────────────────────────────
$back = [Drawing.Bitmap]::FromFile((Join-Path $SrcDir '덮힌카드.png'))
$out = New-Canvas $back
Clear-Outside $out
$out.Save((Join-Path $OutDir 'card_back.png'), [Drawing.Imaging.ImageFormat]::Png)
$out.Dispose(); $back.Dispose()

Write-Host ("카드 그림 " + (Get-ChildItem $OutDir -Filter *.png).Count + "장을 만들었습니다: $OutDir")
