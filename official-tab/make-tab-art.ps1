# 공식 서버 탭 목록(TAB)에 쓰는 그림 글자를 만든다.
#   - 로고 "DB SERVER" (빛이 지나가는 움직임 12장)
#   - 작은 그림: 트로피·검·교차 검·모래시계·사람·점·구분선
# 결과는 이 폴더의 assets/ 아래에 생기고, official-pack.ps1이 DB_official.zip에 넣는다.
#
# 글자 번호 (글꼴 taggame:tab)
#   E200~E223  로고 12장(장마다 3조각)   E110 트로피   E111 검      E112 교차 검
#   E113 모래시계  E114 사람     E115 점(흰색, 글자색으로 물듦)  E120~E123 구분선 4조각(흰색, 물듦)
#
# 그림은 GUI 크기 3 기준으로 글자 한 칸 = 3픽셀 해상도로 그린다(팩 전체 기준과 같음).

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ErrorActionPreference = 'Stop'

# 로고 글꼴은 팩에 든 것(paperlogy_bold)을 꺼내 쓴다 — 서버 글씨와 같은 모양이 되게
$FontPath = Join-Path $env:TEMP 'paperlogy_bold_tabart.ttf'
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $PSScriptRoot '..\DB_full.zip'))
try { [IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry('assets/minecraft/font/paperlogy_bold.ttf'), $FontPath, $true) }
finally { $zip.Dispose() }

$root = $PSScriptRoot
$tex = Join-Path $root 'assets\taggame\textures\font\tab'
$fontDir = Join-Path $root 'assets\taggame\font'
New-Item -ItemType Directory -Force $tex, $fontDir | Out-Null

function C([string]$hex, [int]$a = 255) {
    $h = $hex.TrimStart('#')
    [Drawing.Color]::FromArgb($a, [Convert]::ToInt32($h.Substring(0,2),16), [Convert]::ToInt32($h.Substring(2,2),16), [Convert]::ToInt32($h.Substring(4,2),16))
}
function New-Canvas([int]$w, [int]$h) {
    $bmp = [Drawing.Bitmap]::new($w, $h, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'; $g.InterpolationMode = 'HighQualityBicubic'
    $g.Clear([Drawing.Color]::Transparent)
    return @{ bmp = $bmp; g = $g }
}
function Save($cv, [string]$name) { $cv.g.Dispose(); $cv.bmp.Save((Join-Path $tex $name), [Drawing.Imaging.ImageFormat]::Png); $cv.bmp.Dispose() }
# 그림을 가로로 n조각 내어 이름_0.png, 이름_1.png … 로 저장
function Save-Sliced($cv, [string]$name, [int]$n) {
    $cv.g.Dispose()
    $sw = [int]($cv.bmp.Width / $n)
    for ($i = 0; $i -lt $n; $i++) {
        $part = $cv.bmp.Clone([Drawing.Rectangle]::new($i * $sw, 0, $sw, $cv.bmp.Height), $cv.bmp.PixelFormat)
        $part.Save((Join-Path $tex ("{0}_{1}.png" -f $name, $i)), [Drawing.Imaging.ImageFormat]::Png); $part.Dispose()
    }
    $cv.bmp.Dispose()
}
function Poly([float[]]$xy) { $pts = for ($i = 0; $i -lt $xy.Length; $i += 2) { [Drawing.PointF]::new($xy[$i], $xy[$i+1]) }; return ,$pts }

# ── 로고 ────────────────────────────────────────────────────────────────
$pfc = New-Object Drawing.Text.PrivateFontCollection
$pfc.AddFontFile((Resolve-Path $FontPath))
$family = $pfc.Families[0]

$text = 'DB SERVER'
$em = 46                       # 글자 크기(픽셀)
$track = 7                     # 글자 사이 벌림(픽셀)
$fmt = [Drawing.StringFormat]::GenericTypographic
$fmt.FormatFlags = $fmt.FormatFlags -bor [Drawing.StringFormatFlags]::MeasureTrailingSpaces

# 글자마다 테두리 경로를 만들어 벌림을 준다
$path = New-Object Drawing.Drawing2D.GraphicsPath
$x = 0.0
$probe = New-Canvas 10 10
foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    $path.AddString($s, $family, [int][Drawing.FontStyle]::Regular, $em, ([Drawing.PointF]::new($x, 0)), $fmt)
    $w = $probe.g.MeasureString($s, ([Drawing.Font]::new($family, $em, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)), 1000, $fmt).Width
    $x += $w + $track
}
$probe.g.Dispose(); $probe.bmp.Dispose()
$bounds = $path.GetBounds()
$pad = 6
$W = [int][Math]::Ceiling($bounds.Width) + $pad * 2
# 마인크래프트는 그림 글자 한 장이 256픽셀을 넘으면 못 그린다 → 3조각으로 자른다(조각 폭이 3의 배수가 되게)
$W = [int]([Math]::Ceiling($W / 9.0) * 9)
$H = [int][Math]::Ceiling($bounds.Height) + $pad * 2
# 높이를 3의 배수로 맞춰 글자 칸에 딱 떨어지게
$H = [int]([Math]::Ceiling($H / 3.0) * 3)
$m = New-Object Drawing.Drawing2D.Matrix
$m.Translate($pad - $bounds.X, ($H - $bounds.Height) / 2 - $bounds.Y)
$path.Transform($m)
$b = $path.GetBounds()

$frames = 12
for ($f = 0; $f -lt $frames; $f++) {
    $cv = New-Canvas $W $H
    $g = $cv.g
    # 그림자
    $sh = $path.Clone(); $sm = New-Object Drawing.Drawing2D.Matrix; $sm.Translate(0, 3); $sh.Transform($sm)
    $g.FillPath(([Drawing.SolidBrush]::new((C '#2A1A06' 170))), $sh)
    # 바탕 금색 (위 밝게 → 아래 진하게)
    $lg = [Drawing.Drawing2D.LinearGradientBrush]::new(([Drawing.RectangleF]::new($b.X, $b.Y - 1, $b.Width, $b.Height + 2)), (C '#FFE7A8'), (C '#E8952B'), [Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillPath($lg, $path)
    # 지나가는 빛 (프레임마다 왼쪽→오른쪽, 마지막 몇 장은 빛 없이 쉼)
    $span = $W + 120
    $cx = -60 + $span * ($f / ($frames - 4))
    if ($f -lt $frames - 3) {
        $g.SetClip($path)
        $band = New-Object Drawing.Drawing2D.GraphicsPath
        $band.AddPolygon((Poly @(($cx - 14), 0, ($cx + 10), 0, ($cx - 6), $H, ($cx - 30), $H)))
        $g.FillPath(([Drawing.SolidBrush]::new((C '#FFFDF2' 210))), $band)
        $g.ResetClip()
    }
    # 얇은 윤곽
    $g.DrawPath(([Drawing.Pen]::new((C '#7A4A10' 200), 1.2)), $path)
    Save-Sliced $cv ("logo_{0:D2}" -f $f) 3
}
$logoW = $W; $logoH = $H

# ── 작은 그림 (32×32, 글자 높이 9칸) ────────────────────────────────────
$S = 32

# 트로피
$cv = New-Canvas $S $S; $g = $cv.g
$gold = [Drawing.Drawing2D.LinearGradientBrush]::new(([Drawing.Rectangle]::new(0,0,$S,$S)), (C '#FFE9A6'), (C '#E39A2C'), 45)
$pen = [Drawing.Pen]::new((C '#8A5A14'), 2)
$cup = New-Object Drawing.Drawing2D.GraphicsPath
$cup.AddBezier(7,4, 7,17, 11,20, 16,20); $cup.AddBezier(16,20, 21,20, 25,17, 25,4); $cup.CloseFigure()
$g.DrawArc(([Drawing.Pen]::new((C '#E39A2C'), 3)), 2, 6, 9, 10, 90, 180)
$g.DrawArc(([Drawing.Pen]::new((C '#E39A2C'), 3)), 21, 6, 9, 10, 270, 180)
$g.FillPath($gold, $cup); $g.DrawPath($pen, $cup)
$g.FillRectangle($gold, 14, 20, 4, 5)
$g.FillRectangle($gold, 9, 25, 14, 4); $g.DrawRectangle($pen, 9, 25, 14, 4)
$g.FillEllipse(([Drawing.SolidBrush]::new((C '#FFFFFF' 170))), 10, 6, 4, 8)
Save $cv 'trophy.png'

# 검 (비스듬히)
function Draw-Sword($g, [float]$ang, [float]$cx, [float]$cy) {
    $st = $g.Save()
    $g.TranslateTransform($cx, $cy); $g.RotateTransform($ang)
    $blade = New-Object Drawing.Drawing2D.GraphicsPath
    $blade.AddPolygon((Poly @(-2.6,-14, 0,-17, 2.6,-14, 2.6,5, -2.6,5)))
    $g.FillPath(([Drawing.Drawing2D.LinearGradientBrush]::new(([Drawing.RectangleF]::new(-3,-17,6,22)), (C '#FFFFFF'), (C '#9FB3C8'), 0)), $blade)
    $g.DrawPath(([Drawing.Pen]::new((C '#4A5868'), 1.2)), $blade)
    $g.FillRectangle(([Drawing.SolidBrush]::new((C '#E3A23A'))), -7, 5, 14, 3)
    $g.FillRectangle(([Drawing.SolidBrush]::new((C '#6B4423'))), -1.6, 8, 3.2, 6)
    $g.FillEllipse(([Drawing.SolidBrush]::new((C '#E3A23A'))), -2.4, 13, 4.8, 4.8)
    $g.Restore($st)
}
$cv = New-Canvas $S $S; Draw-Sword $cv.g 45 16 15; Save $cv 'sword.png'
$cv = New-Canvas $S $S; Draw-Sword $cv.g 40 16 16; Draw-Sword $cv.g -40 16 16; Save $cv 'swords.png'

# 모래시계
$cv = New-Canvas $S $S; $g = $cv.g
$frame = [Drawing.SolidBrush]::new((C '#C98A3D'))
$g.FillRectangle($frame, 6, 2, 20, 4); $g.FillRectangle($frame, 6, 26, 20, 4)
$glass = New-Object Drawing.Drawing2D.GraphicsPath
$glass.AddPolygon((Poly @(9,6, 23,6, 17,16, 23,26, 9,26, 15,16)))
$g.FillPath(([Drawing.SolidBrush]::new((C '#DDEBFF' 120))), $glass)
$g.FillPolygon(([Drawing.SolidBrush]::new((C '#FFD166'))), (Poly @(11,8, 21,8, 16,15)))
$g.FillPolygon(([Drawing.SolidBrush]::new((C '#FFD166'))), (Poly @(16,19, 22,25, 10,25)))
$g.DrawPath(([Drawing.Pen]::new((C '#8FA3BF'), 1.4)), $glass)
Save $cv 'hourglass.png'

# 사람
$cv = New-Canvas $S $S; $g = $cv.g
$back = [Drawing.SolidBrush]::new((C '#8FA3BF'))
$g.FillEllipse($back, 17, 5, 9, 9); $g.FillPie($back, 13, 15, 17, 18, 180, 180)
$fore = [Drawing.SolidBrush]::new((C '#E8EEF6'))
$g.FillEllipse($fore, 6, 6, 11, 11); $g.FillPie($fore, 1, 18, 21, 20, 180, 180)
Save $cv 'people.png'

# 점 (흰색 — 글자색으로 물들여 상태 색으로 쓴다)
$cv = New-Canvas 24 24; $cv.g.FillEllipse([Drawing.Brushes]::White, 5, 5, 14, 14); Save $cv 'dot.png'

# 구분선 (가운데 진하고 양끝으로 사라짐, 흰색 — 글자색으로 물듦)
# 높이 1칸짜리 그림은 줄 가운데에 둘 수 없어서(ascent는 height를 넘을 수 없음) 한 줄 높이(9칸)로 그리고 가운데에 선을 긋는다
$LW = 600; $cv = New-Canvas $LW 27
for ($i = 0; $i -lt $LW; $i++) {
    $t = [Math]::Abs($i - $LW / 2) / ($LW / 2)
    $a = [int](255 * [Math]::Max(0, 1 - [Math]::Pow($t, 2.2)))
    $cv.bmp.SetPixel($i, 13, [Drawing.Color]::FromArgb($a, 255, 255, 255))
}
Save-Sliced $cv 'line' 4

# ── 글꼴 설정 ───────────────────────────────────────────────────────────
function U([int]$cp) { '\u{0:X4}' -f $cp }
function Bitmap([string]$file, [int]$height, [int]$ascent, [int]$cp) {
    '{"type":"bitmap","file":"taggame:font/tab/' + $file + '","height":' + $height + ',"ascent":' + $ascent + ',"chars":["' + (U $cp) + '"]}'
}
$logoHeight = [int]($logoH / 3)
$prov = New-Object Collections.Generic.List[string]
# 로고: 장마다 3조각 → E200 + 장*3 + 조각
for ($f = 0; $f -lt $frames; $f++) {
    for ($s = 0; $s -lt 3; $s++) { $prov.Add((Bitmap ('logo_{0:D2}_{1}.png' -f $f, $s) $logoHeight ($logoHeight - 4) (0xE200 + $f * 3 + $s))) }
}
$icons = @(@('trophy',0xE110), @('sword',0xE111), @('swords',0xE112), @('hourglass',0xE113), @('people',0xE114))
foreach ($ic in $icons) { $prov.Add((Bitmap ($ic[0] + '.png') 9 8 $ic[1])) }
$prov.Add((Bitmap 'dot.png' 8 7 0xE115))
# 구분선 4조각 → E120~E123
for ($s = 0; $s -lt 4; $s++) { $prov.Add((Bitmap "line_$s.png" 9 8 (0xE120 + $s))) }
# 띄어쓰기 미세 조정: E1F1 = 1칸, E1F2 = 2칸, E1F4 = 4칸, E1F8 = 8칸, E1FF = -1칸
# (그림 글자는 뒤에 1칸이 붙으므로 조각 사이에 E1FF를 끼워 붙인다)
$prov.Add('{"type":"space","advances":{"' + (U 0xE1F1) + '":1,"' + (U 0xE1F2) + '":2,"' + (U 0xE1F4) + '":4,"' + (U 0xE1F8) + '":8,"' + (U 0xE1FF) + '":-1}}')
$json = '{"providers":[' + ($prov -join ',') + ']}'
[IO.File]::WriteAllText((Join-Path $fontDir 'tab.json'), $json, ([Text.UTF8Encoding]::new($false)))

Write-Host "logo ${logoW}x${logoH} (글자 높이 $logoHeight), 그림 $($icons.Count + 2)개 -> $root\assets"