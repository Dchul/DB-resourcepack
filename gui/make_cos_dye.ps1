<#
  염색 창 그림(cos_dye.png)을 cos_hat.png 에서 만들어 낸다.

  칸 자리가 그림과 어긋나면 안 되므로, 이미 자리가 맞는 cos_hat.png 를 바탕으로
  삼아 판을 평평하게 덮고 필요한 칸만 다시 뚫는다. 뚫린 자리는 상자 창의 본래
  칸 그림이 그대로 비쳐 보인다.

  칸 번호 (54칸 상자 기준)
    3 4 5 / 12 13 14 / 21 22 23  … 기본 색 아홉
    10 오른쪽 16                  … 지금 색이 입혀진 치장
    25                            … 염색 지우기
    31                            … 글린트
    45~53                         … 단계별 색 (양끝은 좌우 화살표)
#>
Add-Type -AssemblyName System.Drawing
$dir = $PSScriptRoot
$src = [System.Drawing.Bitmap]::FromFile((Join-Path $dir 'cos_hat.png'))
$out = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.DrawImage($src, 0, 0)
$g.Dispose()

# 판 바탕색 (테두리 안쪽의 평평한 부분에서 뽑는다)
$bg = $src.GetPixel(5, 60)

# 칸 자리 계산: 칸 r행 c열 = (8 + 18c, 43 + 18r) 에서 16x16
function SlotRect([int]$slot) {
    $c = $slot % 9; $r = [Math]::Floor($slot / 9)
    return @( (8 + 18*$c), (43 + 18*$r) )
}

# 1) 칸이 있던 자리를 통째로 판 색으로 덮는다
for ($y = 42; $y -le 155; $y++) {
    for ($x = 4; $x -le 174; $x++) { $out.SetPixel($x, $y, $bg) }
}

# 2) 필요한 칸만 다시 뚫는다 (뚫린 곳은 상자 창 본래 칸 그림이 보인다)
$holes = @(3,4,5, 10,12,13,14,16, 21,22,23,25, 31, 45,46,47,48,49,50,51,52,53)
$clear = [System.Drawing.Color]::FromArgb(0,0,0,0)
foreach ($s in $holes) {
    $p = SlotRect $s
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) { $out.SetPixel($p[0]+$x, $p[1]+$y, $clear) }
    }
}

# 3) 좌우 화살표를 양끝 칸 위에 옮겨 그린다 (원본 아래쪽 띠에서 밝은 점만 가져온다)
function CopyArrow([int]$sx, [int]$sy, [int]$dx, [int]$dy, [int]$w, [int]$h) {
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $p = $script:src.GetPixel($sx+$x, $sy+$y)
            if ($p.A -gt 8 -and $p.R -gt 150) { $script:out.SetPixel($dx+$x, $dy+$y, $p) }
        }
    }
}
$prev = SlotRect 45
$next = SlotRect 53
CopyArrow 14 139 $prev[0] ($prev[1]+2) 18 12
CopyArrow 146 139 $next[0] ($next[1]+2) 18 12

$out.Save((Join-Path $dir 'cos_dye.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose(); $src.Dispose()
Write-Host "cos_dye.png 을 만들었습니다."
