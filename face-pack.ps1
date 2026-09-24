# 로케이터 바(화면 위쪽 띠)에 점 대신 뜨는 스킨 얼굴을 만든다.
#
# 닉네임으로 Mojang에서 스킨을 받아 얼굴 8x8을 오려 내고, 거리별로 줄어드는
# 네 단계(8·7·6·5픽셀)를 9x9 칸에 그려 DB.zip / DB_full.zip / 서버의 풀어 둔 팩에 넣는다.
#
# 스킨을 바꾼 사람이 생기면 그 닉네임만 넘겨 다시 돌리면 된다.
#   .\face-pack.ps1 -Names hzzun9
# 닉네임을 넘기지 않으면 config.yml의 locator-bar.faces에 적힌 사람을 전부 다시 만든다.
#
# 만든 뒤에는 README의 "갱신 절차"대로 커밋·릴리스 업로드·SHA-1 반영을 해야 한다.

param(
    [string[]] $Names,
    [string] $ServerRoot = "C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root  = $PSScriptRoot
$stage = Join-Path $env:TEMP "face-pack-stage"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
$styleDir  = Join-Path $stage "assets\taggame\waypoint_style"
$spriteDir = Join-Path $stage "assets\taggame\textures\gui\sprites\hud\locator_bar_dot"
New-Item -ItemType Directory -Force -Path $styleDir, $spriteDir | Out-Null

if (-not $Names) {
    $cfg = Join-Path $ServerRoot "plugins\TagGame\config.yml"
    $in = $false
    $Names = Get-Content $cfg -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s\sfaces:') { $in = $true; return }
        if ($in) {
            if ($_ -match '^\s\s-\s*(\S+)\s*$') { $Matches[1] } else { $in = $false }
        }
    }
    if (-not $Names) { throw "config.yml의 locator-bar.faces에서 닉네임을 찾지 못했습니다." }
}

# 거리별 얼굴 크기 (가까울 때부터). 마인크래프트가 거리에 따라 앞에서부터 골라 쓴다.
$sizes = 8, 7, 6, 5

foreach ($name in $Names) {
    $id = $name.ToLowerInvariant()

    $uuid = (Invoke-RestMethod "https://api.mojang.com/users/profiles/minecraft/$name").id
    $value = (Invoke-RestMethod "https://sessionserver.mojang.com/session/minecraft/profile/$uuid").properties[0].value
    $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value)) | ConvertFrom-Json
    $skinUrl = $json.textures.SKIN.url

    $skinFile = Join-Path $env:TEMP "skin_$id.png"
    Invoke-WebRequest $skinUrl -OutFile $skinFile
    $skin = [System.Drawing.Bitmap]::FromFile($skinFile)

    # 얼굴(8,8) 위에 모자 층(40,8)을 덮는다. 옛날 64x32 스킨에는 모자 층이 없다.
    $face = New-Object System.Drawing.Bitmap 8, 8
    $g = [System.Drawing.Graphics]::FromImage($face)
    $g.DrawImage($skin, (New-Object System.Drawing.Rectangle 0,0,8,8), 8, 8, 8, 8, [System.Drawing.GraphicsUnit]::Pixel)
    if ($skin.Height -ge 64) {
        $g.DrawImage($skin, (New-Object System.Drawing.Rectangle 0,0,8,8), 40, 8, 8, 8, [System.Drawing.GraphicsUnit]::Pixel)
    }
    $g.Dispose()
    $skin.Dispose()

    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $s = $sizes[$i]
        $canvas = New-Object System.Drawing.Bitmap 9, 9
        $cg = [System.Drawing.Graphics]::FromImage($canvas)
        $cg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $cg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $off = [int][Math]::Floor((9 - $s) / 2)
        $cg.DrawImage($face, $off, $off, $s, $s)
        $cg.Dispose()
        $canvas.Save((Join-Path $spriteDir "face_${id}_$i.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $canvas.Dispose()
    }
    $face.Dispose()

    $sprites = (0..($sizes.Count - 1) | ForEach-Object { "    `"taggame:face_${id}_$_`"" }) -join ",`n"
    "{`n  `"sprites`": [`n$sprites`n  ]`n}" |
        Set-Content (Join-Path $styleDir "face_$id.json") -Encoding utf8

    Write-Host "$name -> taggame:face_$id"
}

# ── 팩에 넣기 ────────────────────────────────────────────────────────────────

function Add-ToZip($zipPath, $stageDir) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Update')
    try {
        Get-ChildItem $stageDir -Recurse -File | ForEach-Object {
            $entry = $_.FullName.Substring($stageDir.Length + 1).Replace('\', '/')
            $old = $zip.GetEntry($entry)
            if ($old) { $old.Delete() }
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry) | Out-Null
        }
    } finally { $zip.Dispose() }
    Write-Host "넣음: $zipPath"
}

Add-ToZip (Join-Path $root "DB.zip") $stage
Add-ToZip (Join-Path $root "DB_full.zip") $stage

$unpacked = Join-Path $ServerRoot "plugins\DBPack\resourcepack"
if (Test-Path $unpacked) {
    Copy-Item (Join-Path $stage "assets\taggame\*") (Join-Path $unpacked "assets\taggame") -Recurse -Force
    Write-Host "넣음: $unpacked"
}

Remove-Item $stage -Recurse -Force
Write-Host "`n끝났습니다. README의 갱신 절차(커밋 → 릴리스 업로드 → SHA-1 반영)를 이어서 하세요."
