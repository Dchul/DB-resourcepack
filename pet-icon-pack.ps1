<#
  치이카와 펫 칸 그림(인형 그림)과 목소리를 팩에 넣는다.

  Pet\chiikawa\icons\ 의 그림을 taggame:pet_<이름> 자산으로 만들어
    - DB.zip          (원본 팩)
    - DB_full.zip     (실제로 손님에게 내려가는 팩)
    - 서버 plugins\DBPack\resourcepack\  (다음 번 ItemsAdder 합치기 때 살아남도록)
  세 곳에 모두 넣는다. (blackjack-pack.ps1과 같은 방식)

  꼬리잡기 플러그인은 종이 아이템에 taggame:pet_<이름> 을 붙여 치이카와 펫 칸을 그린다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root   = $PSScriptRoot
$Src    = Join-Path $Root 'Pet\chiikawa\icons'
$Server = 'C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838'
$Unpacked = Join-Path $Server 'plugins\DBPack\resourcepack'

if (-not (Test-Path $Src)) { throw "아이콘 폴더가 없습니다: $Src" }
$cards = Get-ChildItem $Src -Filter '*.png'
if ($cards.Count -eq 0) { throw "아이콘 폴더에 그림이 없습니다." }

# ── 넣을 파일 목록을 먼저 만든다 (경로 → 내용) ──────────────────
$files = [ordered]@{}
foreach ($c in $cards) {
    $id = 'pet_' + [IO.Path]::GetFileNameWithoutExtension($c.Name)
    $files["assets/taggame/textures/item/$id.png"] = [IO.File]::ReadAllBytes($c.FullName)
    $files["assets/taggame/models/item/$id.json"] = [Text.Encoding]::UTF8.GetBytes(
        '{"parent":"minecraft:item/generated","textures":{"layer0":"taggame:item/' + $id + '"}}')
    $files["assets/taggame/items/$id.json"] = [Text.Encoding]::UTF8.GetBytes(
        '{"model":{"type":"minecraft:model","model":"taggame:item/' + $id + '"}}')
}

# ── 목소리: Pet\chiikawa\sounds\<캐릭터>\tame_1.ogg / injured_*.ogg ──────
#    taggame:chiikawa.<캐릭터>.tame / .hurt 로 들린다 (꼬리잡기 플러그인이 이 이름으로 튼다)
$SoundSrc = Join-Path $Root 'Pet\chiikawa\sounds'
$soundDefs = [ordered]@{}
foreach ($dir in Get-ChildItem $SoundSrc -Directory) {
    $ch = $dir.Name
    $tame = @(); $hurt = @()
    foreach ($ogg in Get-ChildItem $dir.FullName -Filter '*.ogg') {
        $base = [IO.Path]::GetFileNameWithoutExtension($ogg.Name)
        $files["assets/taggame/sounds/chiikawa/$ch/$($ogg.Name)"] = [IO.File]::ReadAllBytes($ogg.FullName)
        if ($base -like 'tame*')    { $tame += "taggame:chiikawa/$ch/$base" }
        if ($base -like 'injured*') { $hurt += "taggame:chiikawa/$ch/$base" }
    }
    if ($tame.Count) { $soundDefs["chiikawa.$ch.tame"] = @{ sounds = $tame } }
    if ($hurt.Count) { $soundDefs["chiikawa.$ch.hurt"] = @{ sounds = $hurt } }
}
$files['assets/taggame/sounds.json'] = [Text.Encoding]::UTF8.GetBytes(($soundDefs | ConvertTo-Json -Depth 5))

function Add-ToZip($zipPath) {
    if (-not (Test-Path $zipPath)) { Write-Host "  (없음, 건너뜀) $zipPath"; return }
    $zip = [IO.Compression.ZipFile]::Open($zipPath, 'Update')
    try {
        foreach ($name in $files.Keys) {
            $old = $zip.Entries | Where-Object { $_.FullName -eq $name }
            if ($old) { $old.Delete() }
            $e = $zip.CreateEntry($name)
            $s = $e.Open()
            $s.Write($files[$name], 0, $files[$name].Length)
            $s.Dispose()
        }
    } finally { $zip.Dispose() }
    Write-Host ("  " + (Split-Path $zipPath -Leaf) + " : " + $files.Count + "개 반영")
}

Add-ToZip (Join-Path $Root 'DB.zip')
Add-ToZip (Join-Path $Root 'DB_full.zip')

if (Test-Path $Unpacked) {
    foreach ($name in $files.Keys) {
        $dest = Join-Path $Unpacked ($name -replace '/', '\')
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        [IO.File]::WriteAllBytes($dest, $files[$name])
    }
    Write-Host ("  풀어 둔 팩 : " + $files.Count + "개 반영")
} else {
    Write-Host "  (없음, 건너뜀) $Unpacked"
}

Write-Host ("치이카와 아이콘 " + $cards.Count + "개, 목소리 " + $soundDefs.Count + "가지를 팩에 넣었습니다.")
