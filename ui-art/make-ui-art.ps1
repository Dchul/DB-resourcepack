# 공식 서버 채팅 줄 앞 아이콘(글꼴 taggame:ui)을 만든다. 꼬리잡기 공식 서버판 text/Tag와 순서가 맞아야 한다.
#   E300~E309  채팅 아이콘 (안내·매칭·게임·탈락·능력·보상·채팅·관리·거절·공지)
#   E320~E324  능력 갈래 배지 (지금은 안 씀)   E330~E334  키 모양 (지금은 안 씀)
#   E340 시계(쿨타임) E341 모래시계(지속) E342 마우스 좌클릭 E343 마우스 우클릭
#   E350 구분선   E351 세로 막대(창 이름·능력 구획 앞, 글자색으로 물듦)
#   E360 [신고하기] 단추  E361 [디스코드] 단추 (/신고 안내 채팅)
#   E3F1 = 1칸 띄움, E3F2 = 2칸, E3FA = 10칸(아이콘 폭, 여러 줄 채팅 들여쓰기), E3FF = -1칸
# 그림은 GUI 크기 3 기준(글자 한 칸 = 3픽셀)으로 그린다. 결과는 이 폴더의 assets/ 아래.

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ErrorActionPreference = 'Stop'

$FontPath = Join-Path $env:TEMP 'paperlogy_bold_uiart.ttf'
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $PSScriptRoot '..\DB_full.zip'))
try { [IO.Compression.ZipFileExtensions]::ExtractToFile($zip.GetEntry('assets/minecraft/font/paperlogy_bold.ttf'), $FontPath, $true) }
finally { $zip.Dispose() }
$pfc = New-Object Drawing.Text.PrivateFontCollection
$pfc.AddFontFile((Resolve-Path $FontPath))
$family = $pfc.Families[0]

$root = $PSScriptRoot
$tex = Join-Path $root 'assets\taggame\textures\font\ui'
$fontDir = Join-Path $root 'assets\taggame\font'
if (Test-Path $tex) { Remove-Item $tex -Recurse -Force }
New-Item -ItemType Directory -Force $tex, $fontDir | Out-Null

function C([string]$hex, [int]$a = 255) {
    $h = $hex.TrimStart('#')
    [Drawing.Color]::FromArgb($a, [Convert]::ToInt32($h.Substring(0,2),16), [Convert]::ToInt32($h.Substring(2,2),16), [Convert]::ToInt32($h.Substring(4,2),16))
}
function New-Canvas([int]$w, [int]$h) {
    $bmp = [Drawing.Bitmap]::new($w, $h, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([Drawing.Color]::Transparent)
    return @{ bmp = $bmp; g = $g }
}
function Save($cv, [string]$name) { $cv.g.Dispose(); $cv.bmp.Save((Join-Path $tex $name), [Drawing.Imaging.ImageFormat]::Png); $cv.bmp.Dispose() }
function Poly([float[]]$xy) { $pts = for ($i = 0; $i -lt $xy.Length; $i += 2) { [Drawing.PointF]::new($xy[$i], $xy[$i+1]) }; return ,$pts }
function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure(); return $p
}
# 글자를 가운데 놓는 테두리 경로
function TextPath([string]$s, [float]$em, [float]$cx, [float]$cy) {
    $fmt = [Drawing.StringFormat]::GenericTypographic
    $p = New-Object Drawing.Drawing2D.GraphicsPath
    $p.AddString($s, $family, [int][Drawing.FontStyle]::Regular, $em, ([Drawing.PointF]::new(0, 0)), $fmt)
    $b = $p.GetBounds()
    $m = New-Object Drawing.Drawing2D.Matrix
    $m.Translate([float]($cx - $b.Width / 2 - $b.X), [float]($cy - $b.Height / 2 - $b.Y))
    $p.Transform($m); return $p
}

# 갈래: 이름, 색 (순서 = 글자 번호)
$kinds = @(
    @{ id='info';    color='#8C9EFF' },
    @{ id='match';   color='#4FB3FF' },
    @{ id='game';    color='#FF9F43' },
    @{ id='kill';    color='#FF6B6B' },
    @{ id='ability'; color='#B78CFF' },
    @{ id='money';   color='#E9A80C' },
    @{ id='chat';    color='#4FD1A5' },
    @{ id='admin';   color='#9AA0AA' },
    @{ id='deny';    color='#FF5A5A' },
    @{ id='notice';  color='#FF7EB6' }
)

# ── 아이콘 (27×27, 글자 높이 9) ─────────────────────────────────
$S = 27
foreach ($k in $kinds) {
    $cv = New-Canvas $S $S; $g = $cv.g
    $col = C $k.color
    $br = [Drawing.SolidBrush]::new($col)
    $white = [Drawing.SolidBrush]::new((C '#FFFFFF'))
    switch ($k.id) {
        'info' {
            $g.FillEllipse($br, 2, 2, 23, 23)
            $g.FillEllipse($white, 12, 6.5, 3.4, 3.4)
            $g.FillRectangle($white, 12, 11.5, 3.4, 9.5)
        }
        'match' {
            # 사람 둘
            $back = [Drawing.SolidBrush]::new((C $k.color 150))
            $g.FillEllipse($back, 14, 3, 9, 9); $g.FillPie($back, 10.5, 13, 16, 17, 180, 180)
            $g.FillEllipse($br, 4.5, 5, 10, 10); $g.FillPie($br, 0.5, 16, 18, 19, 180, 180)
        }
        'game' {
            # 깃발
            $g.FillRectangle($br, 5, 3, 3, 22)
            $g.FillPolygon($br, (Poly @(8,3, 23,3, 19,8.5, 23,14, 8,14)))
        }
        'kill' {
            # 해골
            $g.FillEllipse($br, 3.5, 2, 20, 17)
            $g.FillRectangle($br, 8, 15, 11, 8)
            $dark = [Drawing.SolidBrush]::new((C '#2A0E0E'))
            $g.FillEllipse($dark, 7, 8, 5.5, 5.5); $g.FillEllipse($dark, 14.5, 8, 5.5, 5.5)
            $g.FillPolygon($dark, (Poly @(13.5,14, 12,17, 15,17)))
            $g.FillRectangle($dark, 11, 20, 1.5, 3); $g.FillRectangle($dark, 14.5, 20, 1.5, 3)
        }
        'ability' {
            # 번개
            $g.FillPolygon($br, (Poly @(16,1.5, 5,15, 12.5,15, 10,25.5, 22,10.5, 14.5,10.5, 18,1.5)))
        }
        'money' {
            $g.FillEllipse([Drawing.SolidBrush]::new((C '#B8860B')), 2, 3, 23, 23)
            $g.FillEllipse($br, 2, 1.5, 23, 22.5)
            $g.DrawEllipse([Drawing.Pen]::new((C '#FFF1B8'), 1.6), 6, 5.5, 15, 14.5)
            $tp = TextPath '₩' 13 13.5 12.8
            $g.FillPath([Drawing.SolidBrush]::new((C '#9A6B00')), $tp)
        }
        'chat' {
            $p = RoundRect 2 3 23 16 5
            $g.FillPath($br, $p)
            $g.FillPolygon($br, (Poly @(7,17, 7,24.5, 14,17)))
            foreach ($x in @(7.5, 12, 16.5)) { $g.FillEllipse($white, $x, 9.5, 3.4, 3.4) }
        }
        'admin' {
            # 방패
            $g.FillPolygon($br, (Poly @(13.5,1.5, 24,5, 23,14, 13.5,25.5, 4,14, 3,5)))
            $g.FillPolygon($white, (Poly @(13.5,6, 19.5,8.5, 19,13.5, 13.5,20.5)))
        }
        'notice' {
            # 확성기
            $g.FillPolygon($br, (Poly @(2,10, 8,10, 19,3.5, 19,22.5, 8,16, 2,16)))
            $g.FillRectangle($br, 5, 15, 4.5, 8)
            $pen = [Drawing.Pen]::new($col, 2.2); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
            $g.DrawArc($pen, 17, 7.5, 7, 11, -60, 120)
            $g.FillRectangle($white, 8.2, 11.2, 1.6, 3.6)
        }
        'deny' {
            $g.FillEllipse($br, 2, 2, 23, 23)
            $pen = [Drawing.Pen]::new((C '#FFFFFF'), 3.4); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
            $g.DrawLine($pen, 9, 9, 18, 18); $g.DrawLine($pen, 18, 9, 9, 18)
        }
    }
    Save $cv ("icon_" + $k.id + ".png")
}

# ── 능력 머리말 배지 (E320~) ────────────────────────────────────────────
$pills = @(
    @{ id='active';  color='#FF9F43'; label='발동' },
    @{ id='control'; color='#4FB3FF'; label='조작' },
    @{ id='passive'; color='#3FC495'; label='패시브' },
    @{ id='state';   color='#A77BF0'; label='상태이상' },
    @{ id='note';    color='#6F7684'; label='정보' }
)
function Draw-Pill([string]$label, [string]$fill, [string]$textColor, [string]$border, [string]$name) {
    $H = 27; $em = 19.5
    $probe = TextPath $label $em 0 0
    $tw = $probe.GetBounds().Width
    $W = [int]([Math]::Ceiling(($tw + 14) / 3.0) * 3)
    $cv = New-Canvas $W $H; $g = $cv.g
    $p = RoundRect 0.5 1.5 ($W - 1) ($H - 3) 5
    if ($fill) { $g.FillPath([Drawing.SolidBrush]::new((C $fill)), $p) }
    if ($border) { $g.DrawPath([Drawing.Pen]::new((C $border), 2), $p) }
    $tp = TextPath $label $em ($W / 2) ($H / 2 + 0.3)
    $g.FillPath([Drawing.SolidBrush]::new((C $textColor)), $tp)
    Save $cv $name
}
foreach ($pl in $pills) { Draw-Pill $pl.label $pl.color '#FFFFFF' $null ("pill_" + $pl.id + ".png") }

# ── 조작 키 (E330~) — 테두리만 있는 키 모양 ─────────────────────────────
$keys = @(
    @{ id='click';  label='클릭' },
    @{ id='left';   label='좌클릭' },
    @{ id='right';  label='우클릭' },
    @{ id='shift';  label='쉬프트+클릭' },
    @{ id='f';      label='F' }
)
foreach ($k in $keys) { Draw-Pill $k.label '#3A2F12' '#FFD166' '#FFD166' ("key_" + $k.id + ".png") }

# ── 작은 그림 (E340~) ──────────────────────────────────────────────────
# 시계 (쿨타임)
$cv = New-Canvas 27 27; $g = $cv.g
$pen = [Drawing.Pen]::new((C '#FFFFFF'), 2.6)
$g.DrawEllipse($pen, 3, 3, 21, 21)
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'
$g.DrawLine($pen, 13.5, 13.5, 13.5, 7.5); $g.DrawLine($pen, 13.5, 13.5, 18, 15.5)
Save $cv 'clock.png'
# 모래시계 (지속)
$cv = New-Canvas 27 27; $g = $cv.g
$wb = [Drawing.SolidBrush]::new((C '#FFFFFF'))
$g.FillRectangle($wb, 6, 2, 15, 3); $g.FillRectangle($wb, 6, 22, 15, 3)
$g.DrawPolygon([Drawing.Pen]::new((C '#FFFFFF'), 2.2), (Poly @(8,5, 19,5, 15,13.5, 19,22, 8,22, 12,13.5)))
$g.FillPolygon($wb, (Poly @(10,17.5, 17,17.5, 18,21, 9,21)))
Save $cv 'hourglass.png'

# 마우스 (E342 좌클릭, E343 우클릭) — 누르는 쪽 단추만 노랗게
foreach ($side in @('left', 'right')) {
    $cv = New-Canvas 21 27; $g = $cv.g
    $body = RoundRect 2 2 17 23 8
    $g.FillPath([Drawing.SolidBrush]::new((C '#2A2D34')), $body)
    $g.SetClip($body)
    $bx = if ($side -eq 'left') { 2 } else { 10.5 }
    $g.FillRectangle([Drawing.SolidBrush]::new((C '#FFD166')), $bx, 2, 8.5, 10)
    $g.ResetClip()
    $g.DrawPath([Drawing.Pen]::new((C '#D8DCE3'), 1.8), $body)
    $g.DrawLine([Drawing.Pen]::new((C '#D8DCE3'), 1.4), 10.5, 2, 10.5, 12)
    $g.DrawLine([Drawing.Pen]::new((C '#D8DCE3'), 1.4), 2, 12, 19, 12)
    Save $cv "mouse_$side.png"
}

# ── 구분선 (E350) — 왼쪽은 진하고 오른쪽으로 사라짐, 흰색이라 글자색으로 물든다 ──
$LW = 240; $cv = New-Canvas $LW 27
for ($i = 0; $i -lt $LW; $i++) {
    $t = $i / $LW
    $a = [int](255 * [Math]::Max(0, 1 - [Math]::Pow($t, 1.6)))
    $cv.bmp.SetPixel($i, 13, [Drawing.Color]::FromArgb($a, 255, 255, 255))
    $cv.bmp.SetPixel($i, 14, [Drawing.Color]::FromArgb([int]($a * 0.35), 255, 255, 255))
}
Save $cv 'line.png'

# ── 세로 막대 (E351) — 구획 머리 앞에 세우는 색 막대, 글자색으로 물든다 ──
$cv = New-Canvas 6 27
$cv.g.FillRectangle([Drawing.Brushes]::White, 0, 1, 6, 25)
Save $cv 'bar.png'

# ── 채팅 단추 (E360~) — 채팅에서 누르는 단추. 아래 3픽셀을 어둡게 해 눌리는 단추처럼 보이게 한다 ──
$buttons = @(
    @{ id='report';  label='신고하기'; fill='#E5484D'; shade='#9E2A2E' },
    @{ id='discord'; label='디스코드'; fill='#5865F2'; shade='#3A43A8' }
)
foreach ($b in $buttons) {
    $H = 27; $em = 18
    $tw = (TextPath $b.label $em 0 0).GetBounds().Width
    $W = [int]([Math]::Ceiling(($tw + 24) / 3.0) * 3)
    $cv = New-Canvas $W $H; $g = $cv.g
    $g.FillPath([Drawing.SolidBrush]::new((C $b.shade)), (RoundRect 0.5 1 ($W - 1) ($H - 1.5) 6))
    $g.FillPath([Drawing.SolidBrush]::new((C $b.fill)), (RoundRect 0.5 1 ($W - 1) ($H - 4.5) 6))
    $g.FillPath([Drawing.SolidBrush]::new((C '#FFFFFF')), (TextPath $b.label $em ($W / 2) (($H - 3) / 2 + 1)))
    Save $cv ("button_" + $b.id + ".png")
}

# ── 글꼴 설정 ───────────────────────────────────────────────────────────
function U([int]$cp) { '\u{0:X4}' -f $cp }
function Bitmap([string]$file, [int]$height, [int]$ascent, [int]$cp) {
    '{"type":"bitmap","file":"taggame:font/ui/' + $file + '","height":' + $height + ',"ascent":' + $ascent + ',"chars":["' + (U $cp) + '"]}'
}
$prov = New-Object Collections.Generic.List[string]
for ($i = 0; $i -lt $kinds.Count; $i++) {
    $prov.Add((Bitmap ("icon_" + $kinds[$i].id + ".png") 9 8 (0xE300 + $i)))
}
for ($i = 0; $i -lt $pills.Count; $i++) { $prov.Add((Bitmap ("pill_" + $pills[$i].id + ".png") 9 8 (0xE320 + $i))) }
for ($i = 0; $i -lt $keys.Count; $i++) { $prov.Add((Bitmap ("key_" + $keys[$i].id + ".png") 9 8 (0xE330 + $i))) }
$prov.Add((Bitmap 'clock.png' 9 8 0xE340))
$prov.Add((Bitmap 'hourglass.png' 9 8 0xE341))
$prov.Add((Bitmap 'mouse_left.png' 9 8 0xE342))
$prov.Add((Bitmap 'mouse_right.png' 9 8 0xE343))
$prov.Add((Bitmap 'line.png' 9 8 0xE350))
$prov.Add((Bitmap 'bar.png' 9 8 0xE351))
for ($i = 0; $i -lt $buttons.Count; $i++) { $prov.Add((Bitmap ("button_" + $buttons[$i].id + ".png") 9 8 (0xE360 + $i))) }
$prov.Add('{"type":"space","advances":{"' + (U 0xE3F1) + '":1,"' + (U 0xE3F2) + '":2,"' + (U 0xE3F4) + '":4,"' + (U 0xE3F8) + '":8,"' + (U 0xE3FA) + '":10,"' + (U 0xE3FF) + '":-1}}')
$json = '{"providers":[' + ($prov -join ',') + ']}'
[IO.File]::WriteAllText((Join-Path $fontDir 'ui.json'), $json, ([Text.UTF8Encoding]::new($false)))
Write-Host "ui 글꼴: $($kinds.Count)개 -> $root\assets"
