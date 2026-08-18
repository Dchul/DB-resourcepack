<#
  gui 폴더의 창 그림을 DB.zip 안에 넣는 스크립트.

  하는 일 세 가지.

  1) 상자 창(54칸)의 바탕 그림을 새 것으로 바꾼다.
     원본이 두 장으로 나뉘어 있다.
       generic_54_base.png  … 칸 자리와 아래쪽 소지품 칸만 있고 테두리가 없다.
                               게임이 원래 자리에 그대로 쓰는 그림이다.
       generic_54_frame.png … 바깥 테두리와 판. 위쪽에 26칸만큼 여백을 두고 그려져 있다.
     두 장을 26칸만큼 맞춰 겹쳐서 한 장으로 만들어 넣는다.

  2) 창 그림들(치장 네 장 · 도구 치장 여섯 장 · 뽑기 미리보기)은 겹쳐 그리는
     그림이라 글자 하나에 그림 한 장을 담는 방식으로 넣는다. 창 제목에 그 글자를
     적으면 창 위에 그림이 그려진다. 위로 26칸 올려 붙도록 값(39)을 맞춰 두었다.

     뽑기 미리보기 창은 창 이름까지 그림에 그려져 있다. 위쪽 보라색 띠는
     "여기는 비워 둔다"는 표시라 넣기 전에 지운다.

  3) 치장 창의 단추들은 그림에 이미 그려져 있으므로, 그 자리에 놓는 물건은
     보이지 않아야 한다. 아무것도 안 보이는 물건 모양을 하나 만들어 넣는다.

  그림을 고쳤으면 이 스크립트를 다시 돌리고, 그 다음 README의 갱신 절차를 따른다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$Root = $PSScriptRoot
$Gui  = Join-Path $Root 'gui'
$Zip  = Join-Path $Root 'DB.zip'
if (-not (Test-Path $Zip)) { throw "DB.zip이 없습니다: $Zip" }
if (-not (Test-Path $Gui)) { throw "gui 폴더가 없습니다: $Gui" }

# 테두리 그림이 위에 두고 있는 여백. 이만큼 올려야 창의 맨 위와 맞는다.
$FrameTop = 26

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("guipack_" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tmp | Out-Null

try {
    # ── 1) 상자 창 바탕 한 장으로 합치기 ─────────────────────────
    $base  = [System.Drawing.Bitmap]::FromFile((Join-Path $Gui 'generic_54_base.png'))
    $frame = [System.Drawing.Bitmap]::FromFile((Join-Path $Gui 'generic_54_frame.png'))
    $out   = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g     = [System.Drawing.Graphics]::FromImage($out)
    $g.CompositingMode = 'SourceOver'
    $g.InterpolationMode = 'NearestNeighbor'
    $g.PixelOffsetMode = 'Half'
    $g.DrawImage($base, 0, 0, 256, 256)
    $g.DrawImage($frame, (New-Object System.Drawing.Rectangle(0, -$FrameTop, 256, 256)),
                 0, 0, 256, 256, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $merged = Join-Path $tmp 'generic_54.png'
    $out.Save($merged, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose(); $base.Dispose(); $frame.Dispose()

    # ── 2) 뽑기 미리보기 창 그림 두 장 ───────────────────────────
    #    창 이름("뽑기 미리보기")과 위쪽 보라색 띠까지 그림에 다 그려져 있으므로
    #    손대지 않고 그대로 넣는다. 창 제목에는 아무 글자도 적지 않는다
    #    (적으면 보라색 띠 위에 '큰 상자' 자리 글씨가 겹쳐 보인다).
    $previewPaths = @{}
    foreach ($n in 'gacha_preview','gacha_preview_tool') {
        $previewPaths[$n] = Join-Path $Gui "$n.png"
    }

    # ── 3) 아무것도 안 보이는 물건 그림 ──────────────────────────
    $blank = New-Object System.Drawing.Bitmap(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $blankPath = Join-Path $tmp 'blank.png'
    $blank.Save($blankPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $blank.Dispose()

    # ── 3-1) 염색 창의 색 네모 ───────────────────────────────────
    #    흰 네모 한 장에 색을 입히는 방식이라, 테두리는 조금 어둡게 그려 두면
    #    색이 입혀졌을 때 저절로 같은 색의 진한 테두리가 된다.
    $sw = New-Object System.Drawing.Bitmap(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            if ($x -eq 0 -or $y -eq 0 -or $x -eq 15 -or $y -eq 15) {
                $sw.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0,0,0,0))
            } elseif ($x -eq 1 -or $y -eq 1 -or $x -eq 14 -or $y -eq 14) {
                $sw.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255,90,90,90))
            } else {
                $sw.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255,255,255,255))
            }
        }
    }
    $swatchPath = Join-Path $tmp 'swatch.png'
    $sw.Save($swatchPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $sw.Dispose()

    # ── zip 에 넣기 ──────────────────────────────────────────────
    $archive = [System.IO.Compression.ZipFile]::Open($Zip, 'Update')

    function Put-Text([string]$entryName, [string]$text) {
        $old = $script:archive.GetEntry($entryName)
        if ($old) { $old.Delete() }
        $e = $script:archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $sw = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
        $sw.Write($text); $sw.Flush(); $sw.Dispose()
    }
    function Put-File([string]$entryName, [string]$sourcePath) {
        $old = $script:archive.GetEntry($entryName)
        if ($old) { $old.Delete() }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $script:archive, $sourcePath, $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal)
    }

    try {
        Put-File 'assets/minecraft/textures/gui/container/generic_54.png' $merged

        foreach ($n in 'cos_home','cos_hat','cos_back','cos_hand','cos_dye',
                       'tool_home','tool_axe','tool_hoe','tool_pickaxe','tool_rod','tool_sword','tool_bow',
                       'pet_list') {
            Put-File "assets/taggame/textures/gui/$n.png" (Join-Path $Gui "$n.png")
        }
        Put-File 'assets/taggame/textures/gui/gacha_preview.png'      $previewPaths['gacha_preview']
        Put-File 'assets/taggame/textures/gui/gacha_preview_tool.png' $previewPaths['gacha_preview_tool']

        # 글자 하나 = 그림 한 장. 앞의 세 글자는 좌우로 밀어 주는 빈 글자다.
        #   e080 : 왼쪽으로 8칸 (제목이 시작되는 자리를 창 왼쪽 끝으로 되돌린다)
        #   e081 : 그림 폭만큼 되돌리기
        #   e082 : 다시 제목 글자가 원래 시작하던 자리로 (그림 뒤에 글자를 적을 때)
        #   e090~e093 : 첫 화면 / 모자 / 등 / 왼손
        #   e094 : 뽑기 미리보기 (펫·칭호·치장)
        #   e095~e09a : 도구 치장 — 첫 화면 / 도끼 / 괭이 / 곡괭이 / 낚싯대 / 검
        #   e09b : 도구 치장 뽑기 미리보기 (위쪽에 갈래 단추가 있다)
        #   e09c : 펫 목록 (칸 36개 + 아래 좌우 화살표)
        #   e09d : 도구 치장 — 활
        $guiFont = @"
{
  "providers": [
    { "type": "space", "advances": { "$([char]0xE080)": -8, "$([char]0xE081)": -257, "$([char]0xE082)": 9 } },
    { "type": "bitmap", "file": "taggame:gui/cos_home.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE090)"] },
    { "type": "bitmap", "file": "taggame:gui/cos_hat.png",       "height": 256, "ascent": 39, "chars": ["$([char]0xE091)"] },
    { "type": "bitmap", "file": "taggame:gui/cos_back.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE092)"] },
    { "type": "bitmap", "file": "taggame:gui/cos_hand.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE093)"] },
    { "type": "bitmap", "file": "taggame:gui/gacha_preview.png", "height": 256, "ascent": 39, "chars": ["$([char]0xE094)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_home.png",     "height": 256, "ascent": 39, "chars": ["$([char]0xE095)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_axe.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE096)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_hoe.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE097)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_pickaxe.png",  "height": 256, "ascent": 39, "chars": ["$([char]0xE098)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_rod.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE099)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_sword.png",    "height": 256, "ascent": 39, "chars": ["$([char]0xE09A)"] },
    { "type": "bitmap", "file": "taggame:gui/gacha_preview_tool.png", "height": 256, "ascent": 39, "chars": ["$([char]0xE09B)"] },
    { "type": "bitmap", "file": "taggame:gui/pet_list.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE09C)"] },
    { "type": "bitmap", "file": "taggame:gui/tool_bow.png",      "height": 256, "ascent": 39, "chars": ["$([char]0xE09D)"] },
    { "type": "bitmap", "file": "taggame:gui/cos_dye.png",       "height": 256, "ascent": 39, "chars": ["$([char]0xE09E)"] }
  ]
}
"@
        Put-Text 'assets/taggame/font/gui.json' $guiFont
        Put-File 'assets/taggame/textures/item/blank.png' $blankPath
        Put-Text 'assets/taggame/models/item/blank.json' @'
{
  "parent": "minecraft:item/generated",
  "textures": { "layer0": "taggame:item/blank" }
}
'@
        Put-Text 'assets/taggame/items/blank.json' @'
{
  "model": {
    "type": "minecraft:model",
    "model": "taggame:item/blank"
  }
}
'@
        Put-File 'assets/taggame/textures/item/swatch.png' $swatchPath
        Put-Text 'assets/taggame/models/item/swatch.json' @'
{
  "parent": "minecraft:item/generated",
  "textures": { "layer0": "taggame:item/swatch" }
}
'@
        Put-Text 'assets/taggame/items/swatch.json' @'
{
  "model": {
    "type": "minecraft:model",
    "model": "taggame:item/swatch",
    "tints": [ { "type": "minecraft:dye", "default": -1 } ]
  }
}
'@
    } finally {
        $archive.Dispose()
    }
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

$sha = (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()
Write-Host "창 그림을 DB.zip에 넣었습니다." -ForegroundColor Green
Write-Host "DB.zip SHA-1 = $sha" -ForegroundColor Cyan
