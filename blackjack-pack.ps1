<#
  블랙잭 카드 그림을 팩에 넣는다.

  blackjack\ 폴더의 카드 53장을 taggame 자산으로 만들어
    - DB.zip          (원본 팩)
    - DB_full.zip     (실제로 손님에게 내려가는 팩)
    - 서버 plugins\DBPack\resourcepack\  (다음 번 ItemsAdder 합치기 때 살아남도록)
  세 곳에 모두 넣는다.

  꼬리잡기 플러그인은 종이 아이템에 taggame:card_<무늬>_<끗> 을 붙여 카드를 보여 준다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root   = $PSScriptRoot
$Src    = Join-Path $Root 'blackjack'
$Server = 'C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838'
$Unpacked = Join-Path $Server 'plugins\DBPack\resourcepack'

if (-not (Test-Path $Src)) { throw "blackjack 폴더가 없습니다: $Src (blackjack-cut.ps1을 먼저 돌리세요)" }
$cards = Get-ChildItem $Src -Filter 'card_*.png'
if ($cards.Count -eq 0) { throw "blackjack 폴더에 카드 그림이 없습니다." }

# ── 넣을 파일 목록을 먼저 만든다 (경로 → 내용) ──────────────────
$files = [ordered]@{}
foreach ($c in $cards) {
    $id = [IO.Path]::GetFileNameWithoutExtension($c.Name)
    $files["assets/taggame/textures/item/$id.png"] = [IO.File]::ReadAllBytes($c.FullName)
    $files["assets/taggame/models/item/$id.json"] = [Text.Encoding]::UTF8.GetBytes(
        '{"parent":"minecraft:item/generated","textures":{"layer0":"taggame:item/' + $id + '"}}')
    $files["assets/taggame/items/$id.json"] = [Text.Encoding]::UTF8.GetBytes(
        '{"model":{"type":"minecraft:model","model":"taggame:item/' + $id + '"}}')
}

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

Write-Host ("카드 " + $cards.Count + "장을 팩에 넣었습니다.")
