# 공식 서버 채팅 줄 앞 아이콘(글꼴 taggame:ui)을 만든다. 꼬리잡기 공식 서버판 text/Tag와 순서가 맞아야 한다.
#   E300~E309  아이콘 (안내·매칭·게임·탈락·능력·보상·채팅·관리·거절·공지)
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

# ── 글꼴 설정 ───────────────────────────────────────────────────────────
function U([int]$cp) { '\u{0:X4}' -f $cp }
function Bitmap([string]$file, [int]$height, [int]$ascent, [int]$cp) {
    '{"type":"bitmap","file":"taggame:font/ui/' + $file + '","height":' + $height + ',"ascent":' + $ascent + ',"chars":["' + (U $cp) + '"]}'
}
$prov = New-Object Collections.Generic.List[string]
for ($i = 0; $i -lt $kinds.Count; $i++) {
    $prov.Add((Bitmap ("icon_" + $kinds[$i].id + ".png") 9 8 (0xE300 + $i)))
}
$prov.Add('{"type":"space","advances":{"' + (U 0xE3F1) + '":1,"' + (U 0xE3F2) + '":2,"' + (U 0xE3FA) + '":10,"' + (U 0xE3FF) + '":-1}}')
$json = '{"providers":[' + ($prov -join ',') + ']}'
[IO.File]::WriteAllText((Join-Path $fontDir 'ui.json'), $json, ([Text.UTF8Encoding]::new($false)))
Write-Host "ui 글꼴: $($kinds.Count)개 -> $root\assets"
